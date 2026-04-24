export class CleanupRegistry {
  constructor() {
    this.steps = []
  }

  add(name, action) {
    if (typeof action !== 'function') {
      throw new TypeError(`Cleanup step "${name}" must be a function.`)
    }

    this.steps.push({ name, action })
  }

  async runAll() {
    const failures = []

    while (this.steps.length > 0) {
      const step = this.steps.pop()

      try {
        await step.action()
      } catch (error) {
        failures.push(`${step.name}: ${error.message}`)
      }
    }

    if (failures.length > 0) {
      throw new Error(`Cleanup failed:\n${failures.join('\n')}`)
    }
  }
}
