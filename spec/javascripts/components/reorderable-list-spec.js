/* eslint-env jasmine, jquery */
/* global GOVUK, spyOnEvent */

describe('Reorderable list component', function () {
  'use strict'

  var container
  var element

  beforeEach(function () {
    container = document.createElement('div')
    container.innerHTML =
    '<ol class="app-c-reorderable-list" data-module="reorderable-list">' +
      '<li class="app-c-reorderable-list__item">' +
        '<div class="app-c-reorderable-list__wrapper">' +
          '<div class="app-c-reorderable-list__content">' +
            '<p class="app-c-reorderable-list__title">First attachment</p>' +
          '</div>' +
          '<div class="app-c-reorderable-list__actions">' +
            '<input name="new_order[]" value="1" class="gem-c-input govuk-input govuk-input--width-2" id="input-278a8924" type="text">' +
            '<button type="button" class="js-reorderable-list-up">Up</button>' +
            '<button type="button" class="js-reorderable-list-down">Down</button>' +
          '</div>' +
        '</div>' +
      '</li>' +
      '<li class="app-c-reorderable-list__item">' +
        '<div class="app-c-reorderable-list__wrapper">' +
          '<div class="app-c-reorderable-list__content">' +
            '<p class="app-c-reorderable-list__title">Second attachment</p>' +
          '</div>' +
          '<div class="app-c-reorderable-list__actions">' +
            '<input name="new_order[]" value="2" class="gem-c-input govuk-input govuk-input--width-2" id="input-278a8924" type="text">' +
            '<button type="button" class="js-reorderable-list-up">Up</button>' +
            '<button type="button" class="js-reorderable-list-down">Down</button>' +
          '</div>' +
        '</div>' +
      '</li>' +
    '</ol>'

    document.body.classList.add('js-enabled')
    document.body.appendChild(container)
    element = document.querySelector('[data-module="reorderable-list"]')
  })

  afterEach(function () {
    document.body.removeChild(container)
  })

  describe('when `matchMedia` is not supported', function () {
    var matchMedia = window.matchMedia
    var mockMatchMedia
    var reorderableList

    beforeEach(function () {
      window.matchMedia = mockMatchMedia
      reorderableList = new GOVUK.Modules.ReorderableList()
      spyOn(reorderableList, 'setupResponsiveChecks')
      reorderableList.start($(element))
    })

    afterEach(function () {
      window.matchMedia = matchMedia
    })

    it('should not setup responsive checks', function () {
      expect(reorderableList.setupResponsiveChecks).not.toHaveBeenCalled()
    })

    it('should disable drag and drop', function () {
      expect(reorderableList.sortable.option('disabled')).toBe(true)
    })
  })

  describe('when `matchMedia` is supported', function () {
    var matchMedia = window.matchMedia
    var mockMatchMedia = matchMedia
    var reorderableList

    var matchMediaMock = function (reorderableList, matches) {
      var bindedcheckMode = reorderableList.checkMode.bind(reorderableList)
      reorderableList.mediaQueryList = { matches: matches }
      reorderableList.sortable = new window.Sortable.create(element) // eslint-disable-line new-cap
      spyOn(reorderableList.sortable, 'option')
      bindedcheckMode()
    }

    beforeEach(function () {
      window.matchMedia = mockMatchMedia
      reorderableList = new GOVUK.Modules.ReorderableList()
    })

    afterEach(function () {
      window.matchMedia = matchMedia
    })

    it('should setup responsive checks', function () {
      spyOn(reorderableList, 'setupResponsiveChecks')
      reorderableList.start($(element))

      expect(reorderableList.setupResponsiveChecks).toHaveBeenCalled()
    })

    it('should enable drag and drop if rendered on a large device', function () {
      matchMediaMock(reorderableList, true)

      expect(reorderableList.sortable.option).toHaveBeenCalledWith('disabled', false)
    })

    it('should disable drag and drop if rendered on a small device', function () {
      matchMediaMock(reorderableList, false)

      expect(reorderableList.sortable.option).toHaveBeenCalledWith('disabled', true)
    })
  })

  describe('when clicking the Down button on first item', function () {
    var reorderableList
    var firstItemDownButton
    beforeEach(function () {
      reorderableList = new GOVUK.Modules.ReorderableList()
      reorderableList.start($(element))
      firstItemDownButton = document.querySelector('li:nth-child(1) .js-reorderable-list-down')
      spyOnEvent(firstItemDownButton, 'reorder-move-down')
      firstItemDownButton.click()
    })

    it('should swaps current item with next item', function () {
      var firstItemTitle = document.querySelector('li:nth-child(1) .app-c-reorderable-list__title').textContent
      var secondItemTitle = document.querySelector('li:nth-child(2) .app-c-reorderable-list__title').textContent
      expect(firstItemTitle).toEqual('Second attachment')
      expect(secondItemTitle).toEqual('First attachment')
    })

    it('should update the associated indexes', function () {
      var firstItemNewIndex = document.querySelector('li:nth-child(1) input[type=text]').value
      var secondItemNewIndex = document.querySelector('li:nth-child(2) input[type=text]').value
      expect(firstItemNewIndex).toEqual('1')
      expect(secondItemNewIndex).toEqual('2')
    })

    it('should trigger a reorder-move-down event', function () {
      expect('reorder-move-down').toHaveBeenTriggeredOn(firstItemDownButton)
    })
  })

  describe('when clicking the Up button on the second item', function () {
    var reorderableList
    var secondItemUpButton
    beforeEach(function () {
      reorderableList = new GOVUK.Modules.ReorderableList()
      reorderableList.start($(element))
      secondItemUpButton = document.querySelector('li:nth-child(2) .js-reorderable-list-up')
      spyOnEvent(secondItemUpButton, 'reorder-move-up')
      secondItemUpButton.click()
    })

    it('should swaps current item with previous item', function () {
      var firstItemTitle = document.querySelector('li:nth-child(1) .app-c-reorderable-list__title').textContent
      var secondItemTitle = document.querySelector('li:nth-child(2) .app-c-reorderable-list__title').textContent
      expect(firstItemTitle).toEqual('Second attachment')
      expect(secondItemTitle).toEqual('First attachment')
    })

    it('should update the associated indexes', function () {
      var firstItemNewIndex = document.querySelector('li:nth-child(1) input[type=text]').value
      var secondItemNewIndex = document.querySelector('li:nth-child(2) input[type=text]').value
      expect(firstItemNewIndex).toEqual('1')
      expect(secondItemNewIndex).toEqual('2')
    })

    it('should trigger a reorder-move-up event', function () {
      expect('reorder-move-up').toHaveBeenTriggeredOn(secondItemUpButton)
    })
  })
})