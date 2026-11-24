const HEARTBEAT_MS = 15_000
const MAX_QUEUED_BYTES = 256 * 1024

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
  let waitingForDrain = false
  let queuedBytes = 0
  const queue = []

  function close() {
    if (closed) return
    closed = true
    clearInterval(heartbeat)
    res.off('drain', flush)
    queue.length = 0
    queuedBytes = 0
    if (!res.writableEnded) res.end()
  }

  function enqueue(frame) {
    const bytes = Buffer.byteLength(frame)
    if (queuedBytes + bytes > MAX_QUEUED_BYTES) {
      close()
      return false
    }
    queue.push(frame)
    queuedBytes += bytes
    return true
  }

  function flush() {
    if (closed || res.writableEnded) return
    waitingForDrain = false
    while (queue.length > 0) {
      const frame = queue.shift()
      queuedBytes -= Buffer.byteLength(frame)
      if (!res.write(frame)) {
        waitingForDrain = true
        res.once('drain', flush)
        return
      }
    }
  }

  function writeFrame(frame) {
    if (closed || res.writableEnded) return false
    if (waitingForDrain || queue.length > 0) return enqueue(frame)
    if (!res.write(frame)) {
      waitingForDrain = true
      res.once('drain', flush)
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
