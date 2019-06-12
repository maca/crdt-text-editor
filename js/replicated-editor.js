class ReplicatedEditor extends HTMLElement {
  constructor() { super(); }

  connectedCallback () {
    this._editor = ace.edit(this, {})
  }
};

customElements.define('replicated-editor', ReplicatedEditor);

