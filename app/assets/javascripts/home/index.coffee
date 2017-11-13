tc = {}
currentUserId = undefined
currentUserFullName = undefined
selectedUserId = undefined
$channelList = undefined
$inputText = undefined
$usernameInput = undefined
$statusRow = undefined
$connectPanel = undefined
$newChannelInputRow = undefined
$newChannelInput = undefined
$typingRow = undefined
$typingPlaceholder = undefined
chatWindowHidden = true

handleInputTextKeypress = (event) ->
  if event.keyCode == 13
    App.chatChannel.send({ body: $(this).val(), to_user_id: selectedUserId })
    addMessageToList({
      timestamp: moment.format
      body: $(this).val(),
      sent_by_full_name: currentUserFullName,
      sent_by: currentUserId
    })

    event.preventDefault()
    $(this).val ''
  else
    # notifyTyping()
  return

connectClient = ->
  App.chatChannel = App.cable.subscriptions.create { channel: 'ChatChannel' },
    connected: ->
      updateConnectedUI()

    disconnected: ->
      # Called when the subscription has been terminated by the server

    received: (data) ->
      if data.sent_by == selectedUserId
        addMessageToList(data)
  return

updateConnectedUI = ->
  $inputText.prop('disabled', false).focus()
  return

joinChannel = (_channel) ->
  _channel.join().then (joinedChannel) ->
    console.log 'Joined channel ' + joinedChannel.friendlyName
    updateChannelUI _channel
    tc.currentChannel = _channel
    tc.loadMessages()
    joinedChannel

initChannelEvents = ->
  console.log tc.currentChannel.friendlyName + ' ready.'
  $inputText.prop('disabled', false).focus()
  return

notifyMemberJoined = (member) ->
  notify member.identity + ' joined the channel'
  return

notifyMemberLeft = (member) ->
  notify member.identity + ' left the channel'
  return

notify = (message) ->
  row = $('<div>').addClass('col-md-12')
  row.loadTemplate '#member-notification-template', status: message
  tc.$messageList.append row
  scrollToMessageListBottom()
  return

showTypingStarted = (member) ->
  $typingPlaceholder.text member.identity + ' is typing...'
  return

hideTypingStarted = (member) ->
  $typingPlaceholder.text ''
  return

scrollToMessageListBottom = ->
  tc.$messageList.scrollTop tc.$messageList[0].scrollHeight
  return

updateChannelUI = (selectedChannel) ->
  channelElements = $('.channel-element').toArray()
  channelElement = channelElements.filter((element) ->
    $(element).data().sid == selectedChannel.sid
  )
  channelElement = $(channelElement)
  if tc.currentChannelContainer == undefined and selectedChannel.uniqueName == GENERAL_CHANNEL_UNIQUE_NAME
    tc.currentChannelContainer = channelElement
  tc.currentChannelContainer.removeClass('selected-channel').addClass 'unselected-channel'
  channelElement.removeClass('unselected-channel').addClass 'selected-channel'
  tc.currentChannelContainer = channelElement
  return

showAddChannelInput = ->
  if tc.messagingClient
    $newChannelInputRow.addClass('showing').removeClass 'not-showing'
    $channelList.addClass('showing').removeClass 'not-showing'
    $newChannelInput.focus()
  return

hideAddChannelInput = ->
  $newChannelInputRow.addClass('not-showing').removeClass 'showing'
  $channelList.addClass('not-showing').removeClass 'showing'
  $newChannelInput.val ''
  return

addChannel = (channel) ->
  if channel.uniqueName == GENERAL_CHANNEL_UNIQUE_NAME
    tc.generalChannel = channel
  rowDiv = $('<div>').addClass('row channel-row')
  rowDiv.loadTemplate '#channel-template', channelName: channel.friendlyName
  channelP = rowDiv.children().children().first()
  rowDiv.on 'click', selectChannel
  channelP.data 'sid', channel.sid
  if tc.currentChannel and channel.sid == tc.currentChannel.sid
    tc.currentChannelContainer = channelP
    channelP.addClass 'selected-channel'
  else
    channelP.addClass 'unselected-channel'
  $channelList.append rowDiv
  return

deleteCurrentChannel = ->
  if !tc.currentChannel
    return
  if tc.currentChannel.sid == tc.generalChannel.sid
    alert 'You cannot delete the general channel'
    return
  tc.currentChannel.delete().then (channel) ->
    console.log 'channel: ' + channel.friendlyName + ' deleted'
    setupChannel tc.generalChannel
    return
  return

addChannelEvents = ->
  $('.channel-element').on('click', selectChannel)

showChatWindow = ->
  $('#welcome-window').hide()
  $('#chat-window').show()
  $inputText.focus()

clearChatWindow = ->
  tc.$messageList.html('')
  $inputText.focus()

selectChannel = (event) ->
  if chatWindowHidden
    showChatWindow()
    chatWindowHidden = false
  else
    clearChatWindow()
  target = $(event.target)
  selectedUserId = target.data().userid
  if tc.currentChannelContainer != undefined
    tc.currentChannelContainer.removeClass('selected-channel').addClass('unselected-channel');
  tc.currentChannelContainer = target
  tc.currentChannelContainer.removeClass('unselected-channel').addClass('selected-channel');
  return

disconnectClient = ->
  leaveCurrentChannel()
  $channelList.text ''
  tc.$messageList.text ''
  channels = undefined
  $statusRow.addClass('disconnected').removeClass 'connected'
  tc.$messageList.addClass('disconnected').removeClass 'connected'
  $connectPanel.addClass('disconnected').removeClass 'connected'
  $inputText.removeClass 'with-shadow'
  $typingRow.addClass('disconnected').removeClass 'connected'
  return

$(document).ready ->
  currentUserId = $('#user_id').val()
  currentUserFullName = $('#user_full_name').val()
  tc.$messageList = $('#message-list')
  $channelList = $('#channel-list')
  $inputText = $('#input-text')
  $usernameInput = $('#username-input')
  $statusRow = $('#status-row')
  $connectPanel = $('#connect-panel')
  $newChannelInputRow = $('#new-channel-input-row')
  $newChannelInput = $('#new-channel-input')
  $typingRow = $('#typing-row')
  $typingPlaceholder = $('#typing-placeholder')
  $inputText.on 'keypress', handleInputTextKeypress
  $newChannelInput.on 'keypress', tc.handleNewChannelInputKeypress
  $('#add-channel-image').on 'click', showAddChannelInput
  addChannelEvents()
  connectClient()
  return

notifyTyping = ->
  tc.currentChannel.typing()
  return

tc.handleNewChannelInputKeypress = (event) ->
  if event.keyCode == 13
    tc.messagingClient.createChannel(friendlyName: $newChannelInput.val()).then hideAddChannelInput
    $(this).val ''
    event.preventDefault()
  return

tc.loadChannelList = (handler) ->
  if tc.messagingClient == undefined
    console.log 'Client is not initialized'
    return
  tc.messagingClient.getPublicChannels().then (channels) ->
    tc.channelArray = tc.sortChannelsByName(channels.items)
    $channelList.text ''
    tc.channelArray.forEach addChannel
    if typeof handler == 'function'
      handler()
    return
  return

tc.joinGeneralChannel = ->
  console.log 'Attempting to join "general" chat channel...'
  if !tc.generalChannel
    # If it doesn't exist, let's create it
    tc.messagingClient.createChannel(
      uniqueName: GENERAL_CHANNEL_UNIQUE_NAME
      friendlyName: GENERAL_CHANNEL_NAME).then (channel) ->
      console.log 'Created general channel'
      tc.generalChannel = channel
      tc.loadChannelList tc.joinGeneralChannel
      return
  else
    console.log 'Found general channel:'
    setupChannel tc.generalChannel
  return

tc.loadMessages = ->
  tc.currentChannel.getMessages(MESSAGES_HISTORY_LIMIT).then (messages) ->
    messages.items.forEach tc.addMessageToList
    return
  return

addMessageToList = (data) ->
  rowDiv = $('<div>').addClass('row no-margin')
  rowDiv.loadTemplate $('#message-template'),
    username: data.sent_by_full_name
    date: App.DateFormatter.getTodayDate(data.timestamp)
    body: data.body
  if data.sent_by == currentUserId
    rowDiv.addClass 'own-message'
  tc.$messageList.append rowDiv
  scrollToMessageListBottom()
  return
