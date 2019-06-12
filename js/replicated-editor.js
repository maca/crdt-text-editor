class ReplicatedEditor extends HTMLElement {
  constructor() { super(); }

  connectedCallback () {
    const shadow = this.attachShadow({ mode: 'open' })
      , container = document.createElement('DIV')
      , element = document.createElement('DIV');


    shadow.appendChild(container);
    container.appendChild(element);

    container.style.position = "relative";
    container.style.width = "100vw";
    container.style.height = "100vh";

    element.style.position = "absolute";
    element.style.top = "0";
    element.style.right = "0";
    element.style.bottom = "0";
    element.style.left = "0";

    this._editor = ace.edit(element, {})
  }
};

customElements.define('replicated-editor', ReplicatedEditor);

