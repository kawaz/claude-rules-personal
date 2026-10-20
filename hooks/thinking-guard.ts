import type { On } from 'claude-code'

// 2025-12〜2026-10 の両面 241,077 thinking block の実測 (194 ヒットを 3 lens で分類) から採用。
// ユーザの感情を話題にしている率が高い語だけを残し、frustrated は一人称 (model 自身) を除外。
// 詰問 / 萎縮 / 責め は model 自身の rule 適用文に当たるだけなので入れない。
const ASSUMED_EMOTION = /(?<!\bI(?:'m| am| was|'ve been) )frustrated|怒っ|苛立|叱責|不満|\b(?:upset|angry|annoyed|impatient)\b/iu
const REMINDER = '(reminder) 直前の thinking でユーザの感情・意図を決めつけていた。no-excessive-apology rule を思い出す'
const STATE = { plugin: 'rules-personal', key: 'thinkingGuard' } as const

export function register(on: On): void {
  on('session.start', async ($, e, next) => {
    await $.state.set(STATE, { isInteractive: e.isInteractive, reminderPending: false })
    return next(e)
  })

  on('session.append', { door: 'response' }, async ($, e, next) => {
    if (e.agentId !== undefined) return next(e)
    const { value } = await $.state.get(STATE)
    if (value?.isInteractive && e.message.content.some(block =>
      block.type === 'thinking' && typeof block.thinking === 'string' && ASSUMED_EMOTION.test(block.thinking)
    )) {
      await $.state.set(STATE, { ...value, reminderPending: true })
    }
    return next(e)
  })

  on('prompt.submit', async ($, e, next) => {
    const { value } = await $.state.get(STATE)
    if (!value?.isInteractive || !value.reminderPending) return next(e)
    const result = await next({ ...e, context: [...(e.context ?? []), REMINDER] })
    await $.state.set(STATE, { ...value, reminderPending: false })
    return result
  })
}
