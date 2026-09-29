// Logs every event this plugin can see to JSONL.
//   <dir>/events-<sessionId>-<part>.jsonl   one line per event: seq, time, event, caller, keys, origin
//   <dir>/samples-<sessionId>.jsonl         the first `e` of each event name (clipped)
// <dir> is $MODS_LAB_DIR, or <plugin root>/log when unset.

const CLIP = 1500
const PART_BYTES = 3 * 1024 * 1024 // $.fs.read / write reject over 4 MiB

let dir: string | undefined
let sid = 'unknown'
let part = 0
let seq = 0
let buf: unknown[] = []
let samples: unknown[] = []
const seen = new Set<string>()
let flushing = false

function clip(v: unknown): unknown {
  try {
    const s = JSON.stringify(v)
    if (s === undefined) return String(v)
    return s.length > CLIP ? s.slice(0, CLIP) + '...<clipped>' : JSON.parse(s)
  } catch (err) {
    return `<unserializable: ${String(err)}>`
  }
}

async function append($: any, path: string, lines: unknown[]): Promise<number> {
  let prev = ''
  try { prev = await $.fs.read(path) } catch { prev = '' }
  const next = prev + lines.map((l) => JSON.stringify(l)).join('\n') + '\n'
  await $.fs.write(path, next)
  return next.length
}

async function flush($: any): Promise<void> {
  if (flushing || dir === undefined) return
  if (buf.length === 0 && samples.length === 0) return
  flushing = true
  try {
    const lines = buf; buf = []
    const firsts = samples; samples = []
    if (lines.length > 0) {
      const size = await append($, `${dir}/events-${sid}-${part}.jsonl`, lines)
      if (size > PART_BYTES) part += 1
    }
    if (firsts.length > 0) await append($, `${dir}/samples-${sid}.jsonl`, firsts)
  } finally {
    flushing = false
  }
}

export function register(on: any): void {
  // Registered first, so it is this plugin's outermost hook. It must not touch `$`:
  // at engine.create `$` is still empty.
  on('*', ($: any, e: any, next: any) => {
    const ev = String(next.event)
    seq += 1
    const entry: Record<string, unknown> = {
      n: seq,
      t: Date.now(),
      ev,
      by: next.origin,
      keys: e !== null && typeof e === 'object' ? Object.keys(e) : typeof e,
    }
    if (e && typeof e === 'object' && 'origin' in e) entry.origin = clip(e.origin)
    if (ev === 'ui.render') entry.component = e?.component
    if (ev.startsWith('tool.')) entry.tool = e?.tool
    buf.push(entry)
    if (!seen.has(ev)) {
      seen.add(ev)
      samples.push({ n: seq, ev, by: next.origin, e: clip(e) })
    }
    return next(e)
  })

  on('session.start', async ($: any, e: any, next: any) => {
    dir = (await $.env.get('MODS_LAB_DIR')) ?? `${$.plugin.root}/log`
    sid = await $.session.id()
    $.clock.every(1000, () => { void flush($) })
    return next(e)
  })

  on('session.end', async ($: any, e: any, next: any) => {
    await flush($)
    return next(e)
  })
}
