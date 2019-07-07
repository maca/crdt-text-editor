class ReplicatedEditor extends HTMLElement {
  constructor() {
    super();
    this.emitContentChanged = true;
  }

  set content(nodes) {
    this.nodes = nodes;

    if (!this.editor) { return }

    try {
      this.emitContentChanged = false;
      this.session.doc.setValue(this.text);
    } finally {
      this.emitContentChanged = true;
    }
  }

  set selection({start, end, reverse}) {
    if (!this.editor) { return }

    const rangeStart = this.session.doc.indexToPosition(start)
      , rangeEnd = this.session.doc.indexToPosition(end)
      , selection = { start: rangeStart, end: rangeEnd };

    this.editor.selection.setSelectionRange(selection, reverse);
  }

  get text() {
    return this
      .nodes.map(({value}) => { return value }).join('');
  }

  get session() {
    return this.editor.session;
  }

  dispatch(name, detail) {
    const ev = new CustomEvent(name, { detail: detail });
    this.dispatchEvent(ev);
  }

  contentChanged({ action, start, end, lines }) {
    if (!this.emitContentChanged) { return }
    let ops;

    const from = this.session.doc.positionToIndex(start)
      , changes = lines.join("\n").split('')

    if (action === 'insert') {
      ops = this.contentInserted(from, changes)
    } else if (action === 'remove') {
      ops = this.contentRemoved(from, changes)
    }

    this.dispatch('editorChanged', ops);
  }

  contentInserted(from, changes) {
    const prevNode = this.nodes[from - 1]

    return changes.map((chr, idx) => {
      if (idx === 0 && prevNode) {
        return { op: "addAfter", value: chr, path: prevNode.path };
      } else if (from < 1) {
        return { op: "addAtBeginning", value: chr };
      } else {
        return { op: "add", value: chr };
      }
    });
  }

  contentRemoved(from, changes) {
    const to = from + changes.length
      , slice = this.nodes.slice(from, to)
      , deleteOp = ({path}) => { return { op: 'delete', path: path } }

    return slice.map(deleteOp);
  }

  cursorChanged() {
    if (!this.emitContentChanged) { return }

    const { start, end } = this.editor.selection.getRange()
      , startIndex = this.session.doc.positionToIndex(start)
      , endIndex = this.session.doc.positionToIndex(end)
      , reverse = this.editor.selection.isBackwards()
      , selection = { start: startIndex, end: endIndex, reverse: reverse }

    this.dispatch('selectionChanged', selection);
  }

  connectedCallback () {
    const contentChanged = this.contentChanged.bind(this)
      , cursorChanged = this.cursorChanged.bind(this)

    this.editor = ace.edit(this, {});
    this.editor.$blockScrolling = Infinity;
    this.session.on('change', contentChanged);
    this.editor.selection.on('changeCursor', cursorChanged);
  }
};

customElements.define('replicated-editor', ReplicatedEditor);

