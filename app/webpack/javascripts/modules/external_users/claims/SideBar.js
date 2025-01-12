moj.Modules.SideBar = {
  el: '.totals-summary',
  claimForm: '#claim-form',
  vatfactor: 0.2,
  blocks: [],
  phantomBlockList: ['fixedFees', 'gradFees', 'miscFees', 'warrantFees', 'interimFees', 'transferFees', 'hardshipFees', 'disbursements', 'expenses'],
  totals: {
    fixedFees: 0,
    gradFees: 0,
    miscFees: 0,
    warrantFees: 0,
    interimFees: 0,
    transferFees: 0,
    hardshipFees: 0,
    disbursements: 0,
    expenses: 0,
    vat: 0,
    grandTotal: 0
  },

  init: function () {
    this.bindListeners()
    this.loadBlocks()
    this.loadStaticBlocks()
  },

  loadBlocks: function () {
    const self = this
    self.blocks = self.blocks.filter(function (block) {
      if (!block || !block.config) return false
      return block.config.fn !== 'PhantomBlock'
    })
    $('.js-block.fx-do-init').each(function (id, el) {
      const $el = $(el)
      const fn = $el.data('block-type') ? $el.data('block-type') : 'FeeBlock'
      const options = {
        fn,
        type: $el.data('type'),
        autoVAT: $el.data('autovat'),
        el,
        $el
      }
      const block = new moj.Helpers.Blocks[options.fn](options)
      self.blocks.push(block.init())
      self.removePhantomKey($el.data('type'))
      $el.removeClass('fx-do-init')
    })
  },

  removePhantomKey: function (val) {
    const idx = this.phantomBlockList.indexOf(val)
    if (idx !== -1) {
      this.phantomBlockList.splice(idx, 1)
    }
  },

  loadStaticBlocks: function () {
    const self = this
    let $el

    this.phantomBlockList.forEach(function (val, idx) {
      if ($('.fx-seed-' + val).length) {
        $el = $('.fx-seed-' + val)
        const options = {
          fn: 'PhantomBlock',
          type: val,
          autoVAT: $el.data('autovat'),
          $el: $('.fx-seed-' + val)
        }

        if ($el.data('autovat') === false) {
          options.autoVAT = false
        }
        const block = new moj.Helpers.Blocks[options.fn](options)
        self.blocks.push(block.init())
      }
    })
  },

  render: function () {
    const self = this
    let selector
    let value
    this.sanitzeFeeToFloat()
    $.each(this.totals, function (key, val) {
      selector = '.total-' + key
      value = moj.Helpers.Blocks.formatNumber(val)
      $(self.el).find(selector).html(value)
    })
  },

  recalculate: function () {
    const self = this

    this.totals = {
      fixedFees: 0,
      gradFees: 0,
      miscFees: 0,
      warrantFees: 0,
      interimFees: 0,
      transferFees: 0,
      hardshipFees: 0,
      disbursements: 0,
      expenses: 0,
      vat: 0,
      grandTotal: 0
    }

    self.blocks.forEach(function (block) {
      if (block.isVisible()) {
        block.reload()
        self.totals[block.getConfig('type')] += block.totals.typeTotal
        self.totals.vat += block.totals.vat
        self.totals.grandTotal += block.totals.typeTotal + block.totals.vat
      }
    })
    self.render()
  },

  bindListeners: function () {
    const self = this
    $('#claim-form').on('recalculate', function () {
      self.recalculate()
    })

    $('#claim-form').on('cocoon:after-insert', function (e) {
      self.loadBlocks()
      self.loadStaticBlocks()
      self.recalculate()
    })

    $('#claim-form').on('cocoon:after-remove', function (e) {
      self.loadBlocks()
      self.loadStaticBlocks()
      self.recalculate()
    })
  },

  sanitzeFeeToFloat: function () {
    const self = this
    $.each(this.totals, function (key, val) {
      if (typeof self.totals[key] === 'string') {
        self.totals[key] = self.strAmountToFloat(self.totals[key])
      }
    })
  },

  strAmountToFloat: function (str) {
    if (typeof str === 'undefined') {
      return 0
    }
    return parseFloat(str.replace(',', '').replace(/£/g, ''))
  }

}
