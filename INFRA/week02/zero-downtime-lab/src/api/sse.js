const HEARTBEAT_MS = 15_000

/**
 * SSE 응답을 연다.
 *
 * @param {import('express').Response} res
 * @param {{ lastEventId?: number }} options
 */
export function openSseStream(res, { lastEventId = 0 } = {}) {
  res.writeHead(200, {
    'Content-Type': 'text/event-stream',
    'Cache-Control': 'no-cache',
    Connection: 'keep-alive',
    // 프록시가 버퍼링하면 실시간이 아니게 된다
    'X-Accel-Buffering': 'no',
  })

  let closed = false

  function close() {
    if (closed) return
    closed = true
    clearInterval(heartbeat)
    if (!res.writableEnded) res.end()
  }

  function writeFrame(frame) {
    if (closed || res.writableEnded) return false
    // 느린 클라이언에 무제한 버퍼를 쌓지 않는다. 버퍼가 차면
    // 연결을 닫고 EventSource가 Last-Event-ID로 재연결하게 한다.
    if (!res.write(frame)) {
      close()
      return false
    }
    return true
  }

  const heartbeat = setInterval(() => writeFrame(': ping\n\n'), HEARTBEAT_MS)

  return {
    lastEventId,
    get closed() { return closed },
    send(event, data, id) {
      const frame = `${id === undefined ? '' : `id: ${id}\n`}event: ${event}\ndata: ${JSON.stringify(data)}\n\n`
      return writeFrame(frame)
    },
    close,
  }
}
