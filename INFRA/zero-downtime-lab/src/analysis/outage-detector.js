/** 실패 유형별 카운터를 0으로 초기화한다 */
function emptyByType() {
  return { network: 0, timeout: 0, server: 0, client: 0 }
}

/**
 * 레코드 스트림에서 순단 구간을 잡아낸다.
 *
 * 순단은 집계된 시계열이 아니라 개별 요청의 연속 실패에서만 보인다.
 * 그래서 버킷이 아니라 레코드를 직접 받는다.
 *
 * @param {{ minConsecutiveFailures: number }} options
 */
export function createOutageDetector({ minConsecutiveFailures }) {
  /** 마지막으로 성공한 요청의 시각. 한 번도 성공한 적 없으면 null */
  let lastSuccessTs = null
  /** 아직 복구되지 않은 연속 실패의 집계 */
  let pendingCount = 0
  let pendingByType = emptyByType()
  let lastFailureTs = null
  const confirmed = []

  /** pending 이 순단 기준을 넘는지 */
  function qualifies() {
    // 한 번도 성공한 적이 없으면 "끊긴" 게 아니라 애초에 닿은 적이 없는 것이다
    return lastSuccessTs !== null && pendingCount >= minConsecutiveFailures
  }

  /** pending 을 순단 객체로 만든다 */
  function build(endTs, ongoing) {
    // 진행 중이면 마지막 실패 시각까지로 잰다
    const measuredEnd = endTs ?? lastFailureTs
    return {
      startTs: lastSuccessTs,
      endTs,
      durationMs: measuredEnd - lastSuccessTs,
      failureCount: pendingCount,
      byType: { ...pendingByType },
      ongoing,
    }
  }

  function resetPending() {
    pendingCount = 0
    pendingByType = emptyByType()
    lastFailureTs = null
  }

  return {
    /**
     * 레코드 하나를 흘려넣는다.
     * @returns {object|null} 순단이 끝났을 때만 그 순단을 반환한다
     */
    push(record) {
      if (record.outcome === 'failure') {
        // 첫 성공 전의 실패는 "순단"이 아니므로 저장하지 않는다.
        if (lastSuccessTs === null) return null
        pendingCount += 1
        if (record.failureType in pendingByType) pendingByType[record.failureType] += 1
        lastFailureTs = record.ts
        return null
      }

      // 성공 레코드: 진행 중이던 실패 구간을 닫는다
      let outage = null
      if (qualifies()) {
        outage = build(record.ts, false)
        confirmed.push(outage)
      }
      resetPending()
      lastSuccessTs = record.ts
      return outage
    },

    /**
     * 실행 종료 시 호출한다.
     * @returns {object|null} 복구되지 않은 순단이 있으면 ongoing 으로 반환
     */
    finish() {
      if (!qualifies()) return null
      const outage = build(null, true)
      confirmed.push(outage)
      resetPending()
      return outage
    },

    outages() {
      return confirmed
    },
  }
}
