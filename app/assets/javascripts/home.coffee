tc = {}
GENERAL_CHANNEL_UNIQUE_NAME = 'general'
GENERAL_CHANNEL_NAME = 'General Channel'
MESSAGES_HISTORY_LIMIT = 50
$channelList = undefined
$inputText = undefined
$usernameInput = undefined
$statusRow = undefined
$connectPanel = undefined
$newChannelInputRow = undefined
$newChannelInput = undefined
$typingRow = undefined
$typingPlaceholder = undefined

handleUsernameInputKeypress = (event) ->
  if event.keyCode == 13
    connectClientWithUsername()
  return

handleInputTextKeypress = (event) ->
  if event.keyCode == 13
    App.chatChannel.send({ sent_by: "me!", body: $(this).val() })
    event.preventDefault()
    $(this).val ''
  else
    # notifyTyping()
  return

connectClientWithUsername = ->
  usernameText = $usernameInput.val()
  $usernameInput.val ''
  if usernameText == ''
    alert 'Username cannot be empty'
    return
  tc.username = usernameText
  App.chatChannel = App.cable.subscriptions.create { channel: 'ChatChannel' },
    connected: ->
      updateConnectedUI()

    disconnected: ->
      # Called when the subscription has been terminated by the server

    received: (data) ->
      addMessageToList(data)
  return

fetchAccessToken = (username, handler) ->
  $.post('/token', {
    identity: username
    device: 'browser'
  }, null, 'json').done((response) ->
    handler response.token
    return
  ).fail (error) ->
    console.log 'Failed to fetch the Access Token with error: ' + error
    return
  return

connectMessagingClient = (token) ->
  # Initialize the IP messaging client
  tc.accessManager = new (Twilio.AccessManager)(token)
  tc.messagingClient = new (Twilio.Chat.Client)(token)
  tc.messagingClient.initialize().then ->
    updateConnectedUI()
    tc.loadChannelList tc.joinGeneralChannel
    tc.messagingClient.on 'channelAdded', tc.loadChannelList
    tc.messagingClient.on 'channelRemoved', tc.loadChannelList
    tc.messagingClient.on 'tokenExpired', refreshToken
    return
  return

refreshToken = ->
  fetchAccessToken tc.username, setNewToken
  return

setNewToken = (tokenResponse) ->
  tc.accessManager.updateToken tokenResponse.token
  return

updateConnectedUI = ->
  $('#username-span').text tc.username
  $statusRow.addClass('connected').removeClass 'disconnected'
  tc.$messageList.addClass('connected').removeClass 'disconnected'
  $connectPanel.addClass('connected').removeClass 'disconnected'
  $inputText.addClass 'with-shadow'
  $typingRow.addClass('connected').removeClass 'disconnected'
  $inputText.prop('disabled', false).focus()
  return

initChannel = (channel) ->
  console.log 'Initialized channel ' + channel.friendlyName
  tc.messagingClient.getChannelBySid channel.sid

joinChannel = (_channel) ->
  _channel.join().then (joinedChannel) ->
    console.log 'Joined channel ' + joinedChannel.friendlyName
    updateChannelUI _channel
    tc.currentChannel = _channel
    tc.loadMessages()
    joinedChannel

initChannelEvents = ->
  console.log tc.currentChannel.friendlyName + ' ready.'
  tc.currentChannel.on 'messageAdded', tc.addMessageToList
  tc.currentChannel.on 'typingStarted', showTypingStarted
  tc.currentChannel.on 'typingEnded', hideTypingStarted
  tc.currentChannel.on 'memberJoined', notifyMemberJoined
  tc.currentChannel.on 'memberLeft', notifyMemberLeft
  $inputText.prop('disabled', false).focus()
  return

setupChannel = (channel) ->
  leaveCurrentChannel().then(->
    initChannel channel
  ).then((_channel) ->
    joinChannel _channel
  ).then initChannelEvents

leaveCurrentChannel = ->
  if tc.currentChannel
    tc.currentChannel.leave().then (leftChannel) ->
      console.log 'left ' + leftChannel.friendlyName
      leftChannel.removeListener 'messageAdded', tc.addMessageToList
      leftChannel.removeListener 'typingStarted', showTypingStarted
      leftChannel.removeListener 'typingEnded', hideTypingStarted
      leftChannel.removeListener 'memberJoined', notifyMemberJoined
      leftChannel.removeListener 'memberLeft', notifyMemberLeft
      return
  else
    Promise.resolve()

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

selectChannel = (event) ->
  target = $(event.target)
  channelSid = target.data().sid
  selectedChannel = tc.channelArray.filter((channel) ->
    channel.sid == channelSid
  )[0]
  if selectedChannel == tc.currentChannel
    return
  setupChannel selectedChannel
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
  $usernameInput.focus()
  $usernameInput.on 'keypress', handleUsernameInputKeypress
  $inputText.on 'keypress', handleInputTextKeypress
  $newChannelInput.on 'keypress', tc.handleNewChannelInputKeypress
  $('#connect-image').on 'click', connectClientWithUsername
  $('#add-channel-image').on 'click', showAddChannelInput
  $('#leave-span').on 'click', disconnectClient
  $('#delete-channel-span').on 'click', deleteCurrentChannel
  return
notifyTyping = (->
  tc.currentChannel.typing()
  return
)

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
    username: data.sent_by
    date: App.DateFormatter.getTodayDate(data.timestamp)
    body: data.body
  if data.sent_by == tc.username
    rowDiv.addClass 'own-message'
  tc.$messageList.append rowDiv
  scrollToMessageListBottom()
  return

tc.sortChannelsByName = (channels) ->
  channels.sort (a, b) ->
    if a.friendlyName == GENERAL_CHANNEL_NAME
      return -1
    if b.friendlyName == GENERAL_CHANNEL_NAME
      return 1
    a.friendlyName.localeCompare b.friendlyName


$('#connect-image').on 'click' , =>
  connectClientWithUsername()
