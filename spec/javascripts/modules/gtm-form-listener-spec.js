var $ = window.jQuery

describe('GTM dataLayer messages for radio button submissions', function () {
  'use strict'

  var form
  var dataLayer
  var gtmFormListener

  beforeEach(function () {
    form = $(`
      <form id="myForm" data-gtm="new_document" onsubmit="return false;">
        <input type="radio" name="supertype" id="radio-news" value="news">
        <input type="radio" name="supertype" id="radio-guidance" value="guidance">
      </form>
    `)
    $(document.body).append(form)
    dataLayer = []
    GTMFormListener.init(dataLayer)
  })

  afterEach(function () {
    form.remove()
    form = undefined
  })

  it('should append the corrent message on submit', function () {
    $('#radio-guidance').click()
    var submitEvent = new Event('submit', {'bubbles': true, 'cancelable': true})
    !document.getElementById('myForm').dispatchEvent(submitEvent)
    expect(dataLayer).toEqual([{new_document: { supertype: 'guidance' }}])
  })
})
