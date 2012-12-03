Spine = require('spine')
List  = require('models/list')
Keys  = require("utils/keys")
$     = Spine.$

class TaskItem extends Spine.Controller
  template: require('views/task')

  elements:
    '.name': 'name'
    '.notes': 'notes'

  events:
    'click .delete': 'remove'
    'click .prioritybtn': 'prioritize'
    'click .checkbox': 'toggleStatus'
    'click .tag': 'tagClick'

    # Editing the actual task
    'click': 'expand'
    'blur .name': 'endEdit'
    'keypress .name': 'endEditOnEnter'

    # Make notes editable
    'focus .notes': 'notesEdit'
    'blur .notes': 'notesSave'


  constructor: ->
    super
    throw "@task required" unless @task
    @task.bind 'update', @update
    @task.bind 'destroy', @release
    @task.bind 'change', @change

  render: =>
    @replace @template @task
    @el.draggable
      revert: "invalid"
      revertDuration: 200
      distance: 10
      scroll: false
      cursorAt:
        top: 15
        right: 30
      helper: =>
        $("body").append("<div class=\"helper\">#{ @task.name }</div>")
        $(".helper")
    @

  # Remove task if it is no longer in the current list
  change: (task) =>
    # Temporary fix
    if List.current.id isnt "all" and List.current.id isnt "filter" and task.list isnt List.current.id
      @release()

  update: =>
    @el.toggleClass "completed", @task.completed
    # Makes tags clickable
    @name.html @task.name.replace(new RegExp("\\s#([^ ]*)", "ig"), ' <span class="tag">#$1</span>')

  # Delete Button
  remove: ->
    @task.destroy()

  toggleStatus: ->
    @task.completed = !@task.completed
    @task.save()

  expand: (e) ->
    if e.target.className isnt "checkbox"
      @el.parent().find(".expanded").removeClass("expanded")
      @el.addClass("expanded animout")
      @el.draggable({ disabled: true })


  # ----------------------------------------------------------------------------
  # PRIORITIES
  # ----------------------------------------------------------------------------

  prioritize: ->
    # Change the priority
    if @task.priority is 3
      @task.updateAttribute "priority", 1
    else
      @task.updateAttribute "priority", @task.priority + 1

    @el.removeClass("p0 p1 p2 p3").addClass("p" + @task.priority)


  # ----------------------------------------------------------------------------
  # NAME
  # ----------------------------------------------------------------------------

  endEdit: ->
    @el.draggable({ disabled: false })
    val = @name.text()
    if val then @task.updateAttribute("name", val) else @task.destroy()

  endEditOnEnter: (e) =>
    if e.which is Keys.ENTER
      e.preventDefault()
      @name.blur()


  # ----------------------------------------------------------------------------
  # NOTES
  # ----------------------------------------------------------------------------

  notesEdit: =>
    if @notes.text() is "Notes" then @notes.text("")
    @notes.removeClass("placeholder")

  notesSave: =>
    text = @notes.text()
    if text is ""
      @notes.text("Notes")
      @notes.addClass("placeholder")
    else
      @task.updateAttribute "notes", text


  # ----------------------------------------------------------------------------
  # TAGS
  # ----------------------------------------------------------------------------

  tagClick: (e) =>
    # Stop task from expanding
    e.stopPropagation()
    List.trigger "changeList",
      name: "Tagged with " + $(e.currentTarget).text()
      id: "filter"
      tasks: Task.tag($(e.currentTarget).text().substr(1))
      disabled: yes
      permanent: yes


module.exports = TaskItem
