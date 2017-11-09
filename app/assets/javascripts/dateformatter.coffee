class App.DateFormatter
  constructor: () ->

  @getTodayDate = (date) ->
    today = moment()
    inputDate = moment(date)
    outputDate = undefined
    if today.format('YYYYMMDD') == inputDate.format('YYYYMMDD')
      outputDate = 'Today - '
    else
      outputDate = inputDate.format('MMM. D - ')
    outputDate = outputDate + inputDate.format('hh:mma')
    outputDate
