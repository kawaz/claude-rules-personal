// rules-personal plugin が $.state に持つ値の契約 (engine が validate 時に照合する)
export interface ThinkingGuardState {
  /** session.start の isInteractive。false (-p 等) なら mod は何もしない */
  isInteractive: boolean
  /** 直前の turn の thinking で決めつけ語が出た。次の prompt.submit で reminder を足して false に戻す */
  reminderPending: boolean
}

declare module 'claude-code' {
  interface PluginState {
    'rules-personal': {
      thinkingGuard: ThinkingGuardState
    }
  }
}
