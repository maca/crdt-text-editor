class ReplicatedEditor extends HTMLElement {
  constructor() {
    super();
    this.emitContentChanged = true;
    this.bufferOperations = false;
    this.operationsBuffer = [];
  }

  set content(nodes) {
    this.nodes = nodes;
    if (this.editor) { this.sync(); }
  }

  get text() {
    return this.visibleNodes
      .map(({value}) => { return value }).join('');
  }

  get visibleNodes() {
    return this.nodes
      .filter(({isDeleted}) => { return !isDeleted });
  }

  get session() {
    return this.editor.session;
  }

  nodeAt(idx) {
    return this.visibleNodes[idx];
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

    this.dispatchEvent(
      new CustomEvent('editorChanged', { detail: ops })
    );

    this.sync()
  }

  contentInserted(from, changes) {
    const prevNode = this.visibleNodes[from - 1]
      , addFun = chr => { return { op: "add", value: chr } }

    if (prevNode) {
      const first = changes.shift()
        , ops = changes.map(addFun)

      ops.unshift({ op: "addAfter", value: first, id: prevNode.id })
      return ops;
    } else {
      return changes.map(addFun);
    }
  }

  contentRemoved(from, changes) {
    const to = from + changes.length
      , slice = this.visibleNodes.slice(from, to)

    return slice.map(({id}) => {
      return { op: 'delete', id: id }
    });
  }

  cursorChanged() {
    if (!this.emitContentChanged) { return }

    const { start, end } = this.editor.selection.getRange()
      , doc = new this.session.doc.constructor(this.text)
      , startIndex = doc.positionToIndex(start)
      , endIndex = doc.positionToIndex(end)
      , startNode = this.nodeAt(startIndex)
      , endNode = this.nodeAt(endIndex)

      this.selection =
        { startNode: startNode, endNode: endNode }
  }

  indexOrPrev(node) {
    let idx = this.nodes.indexOf(node);

    while (idx >= 0 && node.removed) {
      idx = idx - 1;
      node = this.nodes[idx];
    }

    return this.visibleNodes.indexOf(node);
  }

  sync() {
    this.emitContentChanged = false

    try {
      const doc = new this.session.doc.constructor(this.text)
        , { startNode, endNode } = this.selection
        , startIndex = this.indexOrPrev(startNode)
        , endIndex  = this.indexOrPrev(endNode)
        , rangeStart = doc.indexToPosition(startIndex)
        , rangeEnd = doc.indexToPosition(endIndex)
        , range = { start: rangeStart, end: rangeEnd }

      this.session.doc.setValue(this.text)
      this.editor.selection.setSelectionRange(range)
    } finally {
      this.emitContentChanged = true
    }
  }

  connectedCallback () {
    const contentChanged = this.contentChanged.bind(this)
      , cursorChanged = this.cursorChanged.bind(this)
      , lastNode = this.visibleNodes[this.visibleNodes.length - 1]

    this.editor = ace.edit(this, {});
    this.editor.$blockScrolling = Infinity;
    this.selection = { startNode: lastNode, endNode: lastNode }

    this.session.on('change', contentChanged);
    this.editor.selection.on('changeCursor', cursorChanged);

    this.sync()
  }
};

customElements.define('replicated-editor', ReplicatedEditor);

