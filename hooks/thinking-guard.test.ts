import { describe, expect, mock, test } from 'claude-code/testing'

const REMINDER = '(reminder) 直前の thinking でユーザの感情・意図を決めつけていた。no-excessive-apology rule を思い出す'

function response(thinking: string, agentId?: string) {
  return {
    uuid: 'response',
    door: 'response' as const,
    origin: { kind: 'model' as const, model: 'test' },
    message: { type: 'assistant' as const, content: [{ type: 'thinking', thinking }] },
    ...(agentId === undefined ? {} : { agentId }),
  }
}

describe('thinking guard', () => {
  test('reminds once on the next interactive prompt after a main thinking hit', async ($, on) => {
    mock.session(on)
    on('session.start', (_, e) => ({ cwd: e.cwd }))
    on('prompt.submit', (_, e) => ({ text: e.text, context: e.context, origin: e.origin }))
    await $.session.start({ cwd: '/work', surface: 'terminal', isInteractive: true })
    await $.session.append(response('The user is frustrated.'))

    const first = await $.prompt.submit({ text: 'next', wait: false, origin: { kind: 'composer' }, context: ['existing'] })
    expect(first.context).toEqual(['existing', REMINDER])
    const second = await $.prompt.submit({ text: 'later', wait: false, origin: { kind: 'composer' } })
    expect(second.context).toEqual(undefined)
  })

  test('ignores subagent thinking', async ($, on) => {
    mock.session(on)
    on('session.start', (_, e) => ({ cwd: e.cwd }))
    on('prompt.submit', (_, e) => ({ text: e.text, context: e.context, origin: e.origin }))
    await $.session.start({ cwd: '/work', surface: 'terminal', isInteractive: true })
    await $.session.append(response('The user is frustrated.', 'subagent-1'))

    const submitted = await $.prompt.submit({ text: 'next', wait: false, origin: { kind: 'composer' } })
    expect(submitted.context).toEqual(undefined)
  })

  test('does not remind in noninteractive sessions', async ($, on) => {
    mock.session(on)
    on('session.start', (_, e) => ({ cwd: e.cwd }))
    on('prompt.submit', (_, e) => ({ text: e.text, context: e.context, origin: e.origin }))
    await $.session.start({ cwd: '/work', surface: null, isInteractive: false })
    await $.session.append(response('The user is frustrated.'))

    const submitted = await $.prompt.submit({ text: 'next', wait: false, origin: { kind: 'sdk' } })
    expect(submitted.context).toEqual(undefined)
  })
})
