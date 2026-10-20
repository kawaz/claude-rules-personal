import type { On } from 'claude-code'

const ASSUMED_EMOTION = /\b(frustrated|annoyed|irritated|upset|angry|impatient|exasperated)\b|怒って|苛立|不満|詰問|恫喝|萎縮|責め|叱/i
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
