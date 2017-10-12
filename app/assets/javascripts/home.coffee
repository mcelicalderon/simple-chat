$('#connect-image').on 'click' , =>
  App.chat = App.cable.subscriptions.create { channel: 'ChatChannel', username: $('#username-input').value },
    connected: ->
      alert 'Connected'

    disconnected: ->
      # Called when the subscription has been terminated by the server

    received: (data) ->
      alert(data.body)

    send_message: ->
      @perform 'send_message'
