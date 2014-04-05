console.log "running webnote extension 0.0.1"
`
Array.prototype.compare = function (array) {
  i = 0
  while (true) {
    if (this.length == i && array.length == i)
      return 0;
    if (this.length == i)
      return -1;
    if (array.length == i)
      return 1;
    if (this[i] === array[i]) {
      i++;
      continue;
    }
    return this[i] - array[i];
  }
}
`

socket = io.connect 'http://localhost:8000'

socket.on 'connect', () ->

  socket.emit 'url', location.href

  socket.on 'select', (selection, color) ->
    hight_selection selection, color

  socket.on 'note.create', (selection, color, uuid) ->
    create_note selection, color, uuid

  socket.on 'note.edit', (text, id) ->
    $("##{id}").text text
    $("##{id}").attr 'contenteditable', 'true'

  socket.on 'note.lock', (id) ->
    $("##{id}").attr 'contenteditable', 'false'

option =
  bg: 'yellow'
  fg: 'black'

$(document).ready () ->
  tool_bar = '''
  <div class="sh-toolbar">
    <button id="highlight-trigger" class="sh-btn" data-triggered="false">Hight Light</button>
    <button id="note-trigger" class="sh-btn" data-triggered="false">Note</button>
    <select id="fg-selector">
      <option value="black" selected>Fg: Black</option>
      <option value="yellow">Fg: Yellow</option>
      <option value="red">Fg: Red</option>
      <option value="green">Fg: Green</option>
      <option value="blue">Fg: Blue</option>
    </select>
    <select id="bg-selector">
      <option value="yellow" selected>Bg: Yellow</option>
      <option value="red">Bg: Red</option>
      <option value="green">Bg: Green</option>
      <option value="blue">Bg: Blue</option>
    </select>
  </div>
  '''

  $(tool_bar).appendTo 'body'

  $(document).on 'change', '#fg-selector', (e) ->
    option.fg = $('#fg-selector').val()

  $(document).on 'change', '#bg-selector', (e) ->
    option.bg = $('#bg-selector').val()

  $(document).on 'click', '.sh-btn', (e) ->
    e.preventDefault()
    if $(this).attr('data-triggered') == 'true'
      $(this).attr 'data-triggered', 'false'
    else
      $('.sh-btn').attr 'data-triggered', 'false'
      $(this).attr 'data-triggered', 'true'

  $(document).on 'mouseup', (e) ->
    if $('#highlight-trigger').attr('data-triggered') == 'true'
      selection = getSelection()
      if selection.type == 'Range'
        s = createSelection selection
        if selection.removeAllRanges
          selection.removeAllRanges()
        socket.emit 'select', s, option
      return
    if $('#note-trigger').attr('data-triggered') == 'true'
      selection = getSelection()
      if selection.type == 'Caret' or selection.type == 'Range'
        s = createSelection selection
        if selection.removeAllRanges
          selection.removeAllRanges()
        socket.emit 'note.create', s, option
        return

  $(document).on 'focusin', '.sh-note', (e) ->
    id = $(this).attr 'id'
    socket.emit 'note.lock', id

  $(document).on 'keydown', '.sh-note', (e) ->
    id = $(this).attr 'id'
    text = $(this).text()
    socket.emit 'note.edit', text, id

  $(document).on 'focusout', '.sh-note', (e) ->
    id = $(this).attr 'id'
    text = $(this).text()
    socket.emit 'note.edit', text, id

createSelection = (selection) ->
  n1 = getNodePath selection.baseNode
  n2 = getNodePath selection.extentNode
  ns = {}
  reverse = false
  if n1.compare(n2) < 0
    reverse = false
  else if n1.compare(n2) > 0
    reverse = true
  else
    reverse = selection.baseOffset >= selection.extentOffset
  ns.base_node = if reverse then n2 else n1
  ns.base_offset = if reverse then selection.extentOffset else selection.baseOffset
  ns.extent_node = if reverse then n1 else n2
  ns.extent_offset= if reverse then selection.baseOffset else selection.extentOffset
  return ns

getNodePath = (node) ->
  path = []
  while node.tagName != 'BODY'
    `
    for (i = 0; i < node.parentNode.childNodes.length; i++) {
      if (node.parentNode.childNodes[i] === node) {
        path.unshift(i)
        break
      }
    }
    `
    node = node.parentNode
  return path

getNode = (path) ->
  node = $('body')[0]
  for index in path
    node = node.childNodes[index]
  return node

create_note = (selection, color, uuid) ->
  node = getNode selection.extent_node
  offset = selection.extent_offset
  s1 = $(node).text().substring(0, offset)
  s2 = $(node).text().substring(offset)
  l_block = '<span id="sh-lct"></span>'
  $(node).replaceWith(s1 + l_block + s2)
  location = $("#sh-lct").offset()
  $("#sh-lct").remove()
  console.log location

  elmt = "<div id=\"#{uuid}\" class=\"sh-note\" contenteditable=\"true\"></div>"
  $(elmt).css({
    'top': location.top,
    'left': location.left
  }).attr('data-bg', color.bg)
    .attr('data-fg', color.fg)
    .appendTo 'body'

  $('.sh-btn').attr 'data-triggered', 'false'

hight_selection = (selection, color) ->
  base_node = getNode selection.base_node
  base_offset = selection.base_offset
  extent_node = getNode selection.extent_node
  extent_offset = selection.extent_offset

  if base_node == extent_node
    # pass
    s1 = $(base_node).text().substring(0, base_offset)
    s2 = $(base_node).text().substring(base_offset, extent_offset)
    s3 = $(base_node).text().substring(extent_offset)
    new_node = $('<span>').text s2
    new_node.addClass 'sh-highlight'
    new_node.attr('data-bg', color.bg).attr('data-fg', color.fg)
    $(base_node).replaceWith s1 + new_node[0].outerHTML + s3
    return

  tmp_node = base_node
  if tmp_node.nextSibling != null
    tmp_node = tmp_node.nextSibling
    from = 'sibling'
  else
    tmp_node = tmp_node.parentNode
    from = 'child'
  s1 = $(base_node).text().substring(base_offset)
  s2 = $(base_node).text().substring(0, base_offset)
  new_node = $('<span>').text s1
  new_node.addClass 'sh-highlight'
  new_node.attr('data-bg', color.bg).attr('data-fg', color.fg)
  $(base_node).replaceWith s2 + new_node[0].outerHTML
  while tmp_node != extent_node
    if from != 'child' and tmp_node.childNodes.length == 0
      if tmp_node.nextSibling != null
        next_node = tmp_node.nextSibling
        from = 'sibling'
      else
        next_node = tmp_node.parentNode
        from = 'child'
      # TODO color child
      if tmp_node.data.trim() != ''
        new_node = $('<span>').text tmp_node.data
        new_node.addClass 'sh-highlight'
        new_node.attr('data-bg', color.bg).attr('data-fg', color.fg)
        $(tmp_node).replaceWith new_node
      tmp_node = next_node
      continue

    if from != 'child'
      from = 'parent'
      tmp_node = tmp_node.childNodes[0]
      continue

    if tmp_node.nextSibling != null
      from = 'sibling'
      tmp_node = tmp_node.nextSibling
      continue

    from = 'child'
    tmp_node = tmp_node.parentNode
 

  s1 = $(extent_node).text().substring(extent_offset)
  s2 = $(extent_node).text().substring(0, extent_offset)
  new_node = $('<span>').text s2
  new_node.addClass 'sh-highlight'
  new_node.attr('data-bg', color.bg).attr('data-fg', color.fg)
  $(extent_node).replaceWith new_node[0].outerHTML + s1
