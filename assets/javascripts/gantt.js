/*
 * = require jquery
 * = require dnd
 * = require evil
 * = require_self
 */

// evil
window.Gantt = window.Gantt || {};
(function(factory) {
  "use strict";

  if (typeof module !== 'undefined' && typeof module.exports !== 'undefined') {
    module.exports = factory(require('jquery'), window)
  } else {
    /*
     * Evil namespace. Also can be used in Evil Front.
     */
    if ( !window.evil ) window.evil = {};
    window.evil.block = factory(window.$, window)
  }
}(function ($, window) {
  // Helpers
  var $window = $(window);

  // Clone object
  var clone = function (origin) {
    var cloned = { };
    for ( var name in origin ) {
      cloned[name] = origin[name];
    }
    return cloned;
  };

  // Is string ends with substring.
  var endsWith = function (string, substring) {
    return string.substr(-substring.length) === substring;
  };

  /*
   * Add `@data-role` alias to jQuery.
   *
   * Copy from jquery.role by Sasha Koss https://github.com/kossnocorp/role
   */

  var rewriteSelector = function (context, name, pos) {
    var original = context[name];
    if ( !original ) return;

    context[name] = function () {
      arguments[pos] = arguments[pos].replace(
        /@@([\w\u00c0-\uFFFF\-]+)/g, '[data-block~="$1"]');
      arguments[pos] = arguments[pos].replace(
        /@([\w\u00c0-\uFFFF\-]+)/g,  '[data-role~="$1"]');
      return original.apply(context, arguments);
    };

    $.extend(context[name], original);
  };

  rewriteSelector($, 'find', 0);
  rewriteSelector($, 'multiFilter', 0);
  rewriteSelector($.find, 'matchesSelector', 1);
  rewriteSelector($.find, 'matches', 0);

  // Find selector inside base DOM node and cretae class for it.
  var find = function (base, id, selector, klass) {
    var blocks = $().add( base.filter(selector) ).
    add( base.find(selector) );

    if ( blocks.length == 0 ) return;

    var objects = [];

    blocks.each(function (_, node) {
      var block = $(node);

      var obj = clone(klass);
      obj.block = block;

      for ( var i = 0; i < evilBlock.filters.length; i++ ) {
        var stop = evilBlock.filters[i](obj, id);
        if ( stop === false ) return;
      }

      objects.push(obj)
    });

    return function () {
      for ( var i = 0; i < objects.length; i++ ) {
        if (objects[i].init) objects[i].init();
      }
    };
  };

  // If onready event was already happend.
  var ready = false;

  // If onload event was already happend.
  var loaded = false;window
  $window.on('load', function (event) {
    loaded = event;
  });

  // Latest block ID
  var lastBlock = 0;

  /**
   * Create object for every `selector` finded in page and call their
   * `init` method.
   *
   *   evilBlock '.user-page .buttons',
   *     init: ->
   *       @gallery.fotorama()
   *     delete: ->
   *       @deleteForm.submit ->
   *         $('user-status').trigger('deleted')
   *     'click on @deleleLink': (e) ->
   *       e.el.addClass('is-loading')
   *       delete()
   *     'on update': ->
   *       location.reload()
   *
   * Every `data-role="aName"` in HTML will create in object `aName` property
   * with jQuery node.
   *
   * To bind delegate listener just create `EVENT on SELECTOR` method.
   * In first argument it will receive jQuery node of `e.currentTarget`,
   * second will be event object and others will be parameters.
   *
   * To communicate between blocks, just trigget custom events. To receive
   * events from another blocks, create `on EVENT` method. Event object will
   * be on first argument here.
   *
   * Block node will be in `@block` property and you can search only inside
   * block by `@(selector)` method.
   *
   * If your block contrain only `init` method, you can use shortcut:
   *
   *   evilBlock '.block', ->
   *     # init method
   */
  var evilBlock = function (selector, klass) {
    lastBlock += 1;
    var id = lastBlock;

    if ( typeof(klass) == 'function' ) {
      klass = { init: klass };
    }

    evilBlock.defined.push([id, selector, klass]);

    if ( ready ) {
      var init = find($(document), id, selector, klass);
      if ( init ) init();
    }
  };

  /**
   * Vitalize all current blocks inside base. You must call it on every
   * new content from AJAX.
   *
   *   'on click on @load': ->
   *     $.get '/comments', (comments) =>
   *       evilBlock.vitalize $(comments).applyTo(@comments)
   */
  evilBlock.vitalize = function (base) {
    if ( base ) {
      base = $(base);
    } else {
      base = $(document);
    }

    var inits = [];
    for ( var i = 0; i < evilBlock.defined.length; i++ ) {
      var define = evilBlock.defined[i];
      inits.push( find(base, define[0], define[1], define[2]) );
    }

    for ( var i = 0; i < inits.length; i++ ) {
      if ( inits[i] ) inits[i]();
    }
  };

  /**
   * Evil blocks list.
   */
  evilBlock.defined = [];

  /**
   * Filters to process block object and add some extra functions
   * to Evil Blocks. For example, allow to write listeners.
   *
   * Filter will receive block object and unique class ID.
   * If filter return `false`, block will not be created.
   */
  evilBlock.filters = [];

  var filters = evilBlock.filters;

  /**
   * Don’t vitalize already vitalized block.
   *
   * For better perfomance, it should be last filter.
   */
  filters.push(function (obj, id) {
    var ids = obj.block.data('evil-blocks');
    if ( !ids ) {
      ids = [];
    } else if ( ids.indexOf(id) != -1 ) {
      return false;
    }
    ids.push(id);
    obj.block.data('evil-blocks', ids);
  });

  /**
   * Create `this.$()` as alias for `this.block.find()`
   */
  filters.push(function (obj) {
    obj.$ = function (subselector) {
      return obj.block.find(subselector);
    };
  });

  /**
   * Create properties for each element with `data-role`.
   */
  filters.push(function (obj) {
    obj.block.find('[data-role]').each(function (_, el) {
      var roles = el.attributes['data-role'].value.split(' ');
      for ( var i = 0; i < roles.length; i++ ) {
        var role = roles[i];
        if ( !obj[role] ) obj[role] = $();
        if ( obj[role].jquery ) obj[role].push(el);
      }
    });
  });

  /**
   * Syntax sugar to listen block events.
   */
  filters.push(function (obj) {
    for ( var name in obj ) {
      if ( name.substr(0, 3) != 'on ' ) continue;

      var events   = name.substr(3);
      var callback = obj[name];
      delete obj[name];

      (function (events, callback) {
        obj.block.on(events, function (e) {
          if ( e.currentTarget == e.target ) {
            callback.apply(obj, arguments);
          }
        });
      })(events, callback);
    }
  });

  /**
   * Smart `load on window` listener, which fire immediately
   * if page was already loaded.
   */
  filters.push(function (obj) {
    var name     = 'load on window';
    var callback = obj[name];

    if ( !callback ) return;
    delete obj[name];

    if ( loaded ) {
      setTimeout(function () {
        callback.call(obj, loaded);
      }, 1);
    } else {
      $window.on('load', function (event) {
        callback.call(obj, event);
      });
    }
  });

  /**
   * Syntax sugar to listen window and body events.
   */
  filters.push(function (obj) {
    for ( var name in obj ) {
      var elem = false;
      if ( endsWith(name, 'on body') ) {
        elem = $('body');
      } else if ( endsWith(name, 'on window') ) {
        elem = $window;
      }

      if ( !elem ) continue;

      var event    = name.split(' on ')[0];
      var callback = obj[name];
      delete obj[name];

      (function (elem, event, callback) {
        elem.on(event, function () {
          callback.apply(obj, arguments);
        });
      })(elem, event, callback);
    }
  });

  /**
   * Syntax sugar to listen element events.
   */
  filters.push(function (obj) {
    for ( var name in obj ) {
      var parts = name.split(' on ');
      if ( !parts[1] ) continue;

      var callback = obj[name];
      delete obj[name];

      (function (parts, callback) {
        obj.block.on(parts[0], parts[1], function (e) {
          e.el = $(this);
          callback.apply(obj, arguments);
        });
      })(parts, callback);
    }
  });

  /*
   * Run all blocks on load.
   */
  $(document).ready(function () {
    ready = true;
    evilBlock.vitalize();
  });

  return evilBlock
}));

window.dnd = {

  on: function( expression, config ) {

    var els = document.querySelectorAll(expression);

    [].forEach.call(els, function (el) {

      el.addEventListener('dragstart', function (e) {
        e.dataTransfer.effectAllowed = 'move';
        config.start ? config.start(this, e) : 0;
      }, false);

      el.addEventListener('dragenter', function (e) {
        config.enter ? config.enter(this, e) : 0;
      }, false);

      el.addEventListener('dragover', function (e) {
        e.preventDefault();
        e.dataTransfer.dropEffect = 'move';
        config.over ? config.over(this, e) : 0;
      }, false);

      el.addEventListener('dragleave', function (e) {
        config.leave ? config.leave(this, e) : 0;
      }, false );

      el.addEventListener('drop', function (e) {
        e.stopPropagation();
        e.preventDefault();
        config.drop ? config.drop(e.dataTransfer, this, e) : 0;
      }, false);

      el.addEventListener('dragend', function (e) {
        config.end ? config.end(this, e) : 0;
      }, false);
    });
  }
};

// blocks
evil.block('@@cloasable_issue',
  {
    init: function() {
    },
    "click on @switch_button": function(e) {
    }
  }
);

evil.block('@@resizable',
  {
    init: function() {
      this.block.trigger('resize');
    },
    "resize on window": function(ev) {
      this.block.trigger('resiz');
    },
    "on rewidth": function(ev) {
    },
    "on resiz_head": function(ev) {
      var self = this;
      $('.heading .header').each(function(idx) {
        var w = this.width();
      });
    },
    "on resiz": function(ev) {
      this.resize_block(ev, 'issue_', 'i_');
      this.resize_block(ev, 'project_', 'p_');
    },
    resize_block: function (ev, n, m) {
      var r = new RegExp('^' + n + m + '(\\d+)');
      var id = '';

      $.each(ev.target.classList, function(idx, cls){
        if (rez = cls.match(r)) {
          id = rez[1];
        }
      });
      if (id === '') { return };
      $('.gantt.container .chart .heading').height($('.gantt.container .grid .heading').height());
      $('.gantt.container .chart .row_' + m + id).height(this.block.height() - 1);
      $('.gantt.container .border').height($('.gantt.container .grid').height());
    }
  }
);

evil.block('@@movable',
  {
    init: function() {
      this.drag = false;
      this.url = this.block.attr('data-url');
    },
    'pointerdown on @border': function(ev) {
      this.drag = true;
      this.startx = ev.pageX;
      this.gridsize = $('.gantt.container .grid').width();
      this.chartsize = $('.gantt.container .chart').width();
    },
    'pointermove on body': function(ev) {
      if(!this.drag)
        return;
      var w = ev.pageX - this.startx;
      $('.gantt.container .grid').width(this.gridsize + w);
      $('.gantt.container .chart').width(this.chartsize - w);
      $('[data-block="resizable"]').trigger('resiz');
      $('[data-block="resizable"]').trigger('resiz_head');
    },
    'pointerup on body': function(ev) {
      if(!this.drag)
        return;
      this.drag = false;
      var w = ev.pageX - this.startx;
      $('.gantt.container .grid').width(this.gridsize + w);
      $('.gantt.container .chart').width(this.chartsize - w);
      $('[data-block="resizable"]').trigger('resiz_head');
      $.ajax(this.url, {dataType: 'json', data: { name: 'grid_size', value: this.gridsize + w }, method: 'PUT', success: function(res, rep) {
      }});
    }
  }
);
evil.block('@@movable2',
  {
    init: function() {
      this.drag = false;
      this.col = this.block.attr('data-col');
      this.url = this.block.attr('data-url');
    },
    'pointerdown on @border2': function(ev) {
      ev.preventDefault();
      this.drag = true;
      this.startx = ev.pageX;
      this.gsize = $('.heading .header.' + this.col).width();
    },
    'pointermove on body': function(ev) {
      if(!this.drag)
        return;
      var w = ev.pageX - this.startx;
      $('.grid .header.' + this.col).width(this.gsize + w);
      $('[data-block="resizable"]').trigger('resiz_head');
    },
    'pointerup on body': function(ev) {
      if(!this.drag)
        return;
      this.drag = false;
      var w = ev.pageX - this.startx;
      $('.grid .header.' + this.col).width(this.gsize + w);
      $('.grid .issue .field.' + this.col).width(this.gsize + w + 4);
      $('.grid .project_name .field.' + this.col).width(this.gsize + w + 4);
      $('[data-block="resizable"]').trigger('resiz');
      $.ajax(this.url, {dataType: 'json', data: { name: this.col, value: this.gsize + w }, method: 'PUT', success: function(res, rep) {
      }});
    }
  }
);
evil.block('@@inline_editable',
  {
    init: function() {
      this.url = this.block.attr('data-url');
      this.name = this.block.attr('data-name');
    },
    'click on @editable': function(ev) {
      var data = {};
      var self = this;
      $.getJSON(this.url, data, function(ret) {
        $(self.block).html(ret.html);
        evil.block.vitalize();
        self.$('form').on('submit', function(ev) {
          var dat = {};
          dat['value'] = self.$('form [name="' + self.name + '"]').val();

          $.ajax(self.url, {dataType: 'json', data: dat, method: 'PUT', success: function(res, rep) {
            $(self.block).html(res.html);
            evil.block.vitalize();
          }});
          ev.preventDefault();
        });
      });
    }
  }
);
evil.block('@@columnable',
  {
    init: function() {
      this.url = this.block.attr('data-url');
      window.Gantt.columns = $.map(self.$('#column_names option'), function(obj, id) { return $(obj).val(); });
    },
    'click on @right': function(ev) {
      var self = this;
      var ids = $.map(self.$('#available_columns').prop('selectedOptions'), function(obj, id) {
        return $(obj).val();
      });
      $.each(ids, function(idx, obj) {
        self.$('#available_columns option[value="' + obj + '"]').clone().appendTo('#column_names');
        self.$('#available_columns option:selected').attr('selected', false);
        self.$('#available_columns option[value="' + obj + '"]').prop('disabled', true);
      });
      window.Gantt.columns = $.map(self.$('#column_names option'), function(obj, id) { return $(obj).val(); });
      this.apply(ev);
      ev.preventDefault();
    },
    'click on @left': function(ev) {
      var self = this;
      var ids = $.map(self.$('#column_names').prop('selectedOptions'), function(obj, id) {
        return $(obj).val();
      });
      $.each(ids, function(idx, obj) {
        self.$('#column_names option[value="' + obj + '"]').remove();
        self.$('#available_columns option[value="' + obj + '"]').prop('disabled', false);
      });
      window.Gantt.columns = $.map(self.$('#column_names option'), function(obj, id) { return $(obj).val(); });
      this.apply(ev);
      ev.preventDefault();
    },
    apply: function(ev) {
      window.Gantt.query = window.Gantt.query || {};
      window.Gantt.query.column_names = window.Gantt.columns;
      $.ajax(this.url, {dataType: 'json', data: window.Gantt.query, method: 'POST', success: function(res, rep) {
        $('.gantt.container').replaceWith(res.html);
        evil.block.vitalize();
      }});
    },
    'click on @apply': function(ev) {
      this.apply(ev);
      ev.preventDefault();
    }
  }
);
evil.block('@@cloasable_issue',
  {
    init: function() {
      this.url = this.block.attr('data-url');
    },
    "click on @switch_button": function(ev) {
      $.ajax(this.url, {dataType: 'json', data: {}, method: 'POST', success: function(res, rep) {
        $('.gantt.container').replaceWith(res.html);
        evil.block.vitalize();
      }});
      ev.preventDefault();
    }
  }
);

evil.block('@@issue',
  {
    init: function() {
      this.name = this.block.attr('data-name');
      this.url = this.block.attr('data-url');
      window.Gantt.params = window.Gantt.params || {};
    },
    'click on @ok': function(ev) {
      ev.preventDefault();
      var data = {};
      var self = this;
      data[this.name] = {};
      this.$(':input').each(function(idx, item) {
        data[self.name][item.name] = item.value;
      });
      this.block.remove();
      $.ajax(this.url, {dataType: 'json', data: data, method: 'POST', success: function(res, rep) {
        $('.gantt.container').replaceWith(res.html);
        evil.block.vitalize();
      }});
      evil.block.vitalize();
    },
    'click on @cancel': function(ev) {
      this.block.remove();
      ev.preventDefault();
      evil.block.vitalize();
    }
  });

evil.block('@@modal',
  {
    init: function() {
      this.name = this.block.attr('data-name');
      this.url = this.block.attr('data-url');
      window.Gantt.params = window.Gantt.params || {};
    },
    'click on @ok': function(ev) {
      ev.preventDefault();
      var data = {};
      var self = this;
      data[this.name] = [];
      this.$(':checked').each(function(idx, item) {
        data[self.name].push(item.value);
      });
      if (data[this.name].length == 0) {
        data[this.name].push('---');
      }
      $.extend(window.Gantt.params, data);

      this.block.remove();
      window.Gantt.query = window.Gantt.query || {};
      window.Gantt.query.column_names = window.Gantt.columns;
      window.Gantt.query.params = window.Gantt.params;
      $.ajax(this.url, {dataType: 'json', data: window.Gantt.query, method: 'POST', success: function(res, rep) {
        $('.gantt.container').replaceWith(res.html);
        evil.block.vitalize();
      }});
      evil.block.vitalize();

    },
    'click on @clear': function(ev) {
      ev.preventDefault();
      delete window.Gantt.params[this.name]
      window.Gantt.query = window.Gantt.query || {};
      window.Gantt.query.column_names = window.Gantt.columns;
      window.Gantt.query.params = window.Gantt.params;
      window.Gantt.query.clear = [this.name];
      this.block.remove();
      $.ajax(this.url, {dataType: 'json', data: window.Gantt.query, method: 'POST', success: function(res, rep) {
        $('.gantt.container').replaceWith(res.html);
        delete window.Gantt.query.clear;
        evil.block.vitalize();
      }});
      evil.block.vitalize();
    },
    'click on @cancel': function(ev) {
      this.block.remove();
      ev.preventDefault();
      evil.block.vitalize();
    }
  });

evil.block('@@filterable', {
  init: function() {
    this.url = this.block.attr('data-url');
    this.name = this.block.attr('data-name');
  },
  'click on @open': function(ev) {
    $.ajax(this.url, {dataType: 'json', data: { name: this.name }, method: 'GET', success: function(res, rep) {
      $('.gantt.container').append(res.html);
      evil.block.vitalize();
    }});
    ev.preventDefault();
  }
});

evil.block('@@new_issuable', {
  init: function() {
    this.url = this.block.attr('data-url');
    this.name = this.block.attr('data-name');
  },
  'click on @open': function(ev) {
    $.ajax(this.url, {dataType: 'json', data: { name: this.name }, method: 'GET', success: function(res, rep) {
      $('.gantt.container').append(res.html);
      evil.block.vitalize();
    }});
    ev.preventDefault();
  }
});

evil.block('@@issue_addable', {
  init: function() {
    this.url = this.block.attr('data-url');
    this.name = this.block.attr('data-name');
  },
  'click on @new_issue': function(ev) {
  }
});

evil.block('@@settingable',
  {
    init: function() {
      window.Gantt.params = window.Gantt.params || {};
    },
    'change on @baseline': function(ev) {
      var self = this;
      this.$('select option').each(function(idx, item){
        if (self.$('select').val() == item.value) {
          self.url = self.$(item).attr('data-url');
        }
      });
      window.location = this.url;
    }
  });

evil.block('@@printable', {
  init: function() {
    this.block.trigger('prit')
  },
  'prit on window': function(ev) {
    $(document).ready(function(){
      window.print()
    })
    window.onafterprint = function() {
      history.go(-1)
    }
  }
});

evil.block( '@@return_to', {
  init: function() {
    this.block.trigger('return');
  },
  'return on window': function(ev) {
    let url = window.location.href;
    let el = $('#main_menu_top_project li a');

    el.attr('href', el.attr('href') + '?return_to=' + url);
  }
});

evil.block('@@header_toggle', {
  init: function() {
    this.type = this.block.attr('data-type');
  },
  'click on @toggle': function(ev) {
    this.$(".hideable").slideToggle("fast");
    this.$(".menu a div").toggleClass("icon-arrow-down-bold");
    this.$(".menu a div").toggleClass("icon-arrow-up-bold");
  }
});

evil.block('@@new_issue', {
  init: function() {
    this.url = this.block.attr('data-url');
    this.name = this.block.attr('data-name');
  },
  'click on @add_row': function(ev) {
    $.ajax(this.url, { dataType: 'json', method: 'POST', success: function(res, rep) {
      $('.gantt.container').replaceWith(res.html);
      evil.block.vitalize();
    }});
  }
});

evil.block('@@chooseable',
  {
    init: function() {
    },
    'click on @chooseable_button': function(ev) {
      $('.issue .field.actions').toggle();
      $('.issue .field.chooseable_field').toggle();
      $('.header .action_header_text').toggle();
      $('.header .choose_all').toggle();
      $('.menu .actions_menu').toggle('fast');
      this.$(ev.target).toggleClass('chooseable_button icon-list-bulleted');
      this.$(ev.target).toggleClass('chooseable_cancel icon-cancel-alt');
    },
    'click on @choose_all': function(ev) {
      if (this.$(ev.target).is(':checked')) {
        $('.chooseable_field input').each(function () {
          $(this).prop('checked', true);
        })
      } else {
        $('.chooseable_field input').each(function () {
          $(this).prop('checked', false);
        })
      }
    },
    'click on @choose_row': function(ev) {
    }
  }
);

evil.block('@@projects_list',
  {
    init: function() {
      this.url = this.block.attr('data-url');
    },
    'click on @open': function(ev) {
      $.ajax(this.url, {dataType: 'json', data: {}, method: 'POST', success: function(res, rep) {
        $('.gantt.container').append(res.html);
        evil.block.vitalize();
      }});
      ev.preventDefault();
    },
    'click on @href': function(ev) {
      var href = $(ev.target).attr('href');
      window.location = href;
      ev.preventDefault();
    }
  });

evil.block('@@chatable',
  {
    'click on @chat_modal': function(ev) {
      this.url = $(ev.target).attr('href');
      $.ajax(this.url, {dataType: 'json', data: { name: this.name }, method: 'POST', success: function(res, rep) {
        $('.gantt.container').append(res.html);
        evil.block.vitalize();
      }});
      ev.preventDefault();
    }
  }
);

evil.block('@@multimoveable', 
  {
    init: function() {
      this.issue_id = this.block.data('id');
    },
    'click on @send_selected': function(ev) {
      var elements = [];
      $(".chooseable_field input:checked").each (function() {
        elements.push($(this).attr('name'));
      });
      var url = $(ev.target).attr('href');
      var data = {};
      data['issue'] = this.issue_id;
      data['items'] = elements;
      ev.preventDefault();
      $.ajax(url, {dataType: 'json', data: data,  method: 'POST', success: function(res, rep) {
        $('.gantt.container').replaceWith(res.html);
        evil.block.vitalize();
        console.log('done');
      }});
    }
  }
);

evil.block('@@excel_import', 
  {
    'click on @import_modal': function(ev) {
      this.url = $(ev.target).attr('href');
      $.ajax(this.url, {dataType: 'json', method: 'POST', success: function(res, rep) {
        $('.gantt.container').append(res.html);
        evil.block.vitalize();
      }});
      ev.preventDefault();
    },
    'drag on @upload': function(ev) {
      ev.preventDefault();
      ev.stopPropagation();
    },
    'dragover, dragenter on @upload': function(ev) {
      ev.preventDefault();
      ev.stopPropagation();
      this.$(ev.target).addClass('is-dragover');
    },
    'dragleave, dragend on @upload': function(ev) {
      ev.preventDefault();
      ev.stopPropagation();
      this.$(ev.target).removeClass('is-dragover');
    },
    'drop on @upload': function(ev) {
      var droppedFiles = false;
      var fileName = '';

      ev.preventDefault();
      ev.stopPropagation();
      this.$(ev.target).removeClass('is-dragover');
      droppedFiles = ev.originalEvent.dataTransfer.files;
      fileName = droppedFiles[0]['name'];
      $('#filename').html(fileName);
      $('#upload-text').hide();
    }
  }
);

evil.block('@@colourable',
  {
    'click on @colour_rows': function(ev) {
      var colour = this.$(ev.target).attr("name");
      var issues = [];
      $('.chooseable_field input:checked').each(function () {
        var id = $(this).attr('name');
        $(".issue_i_" + id).css("background", colour);
        $(".row_i_" + id).css("background", colour);
        issues.push(id);
        $(this).prop('checked', false);
      })
      $.ajax(this.url, {dataType: 'json', data: data, method: 'POST', success: function(res, rep) {
          $('.gantt.container').replaceWith(res.html);
          evil.block.vitalize();
        }});
      evil.block.vitalize();
    },
    'mouseover on @issue_hover': function(ev) {
      var id = $(ev.target).closest('.issue').attr('name');
      $(".issue_i_" + id).addClass('touchable');
      $(".row_i_" + id).addClass('touchable');
    },
    'mouseout on @issue_hover': function(ev) {
      var id = $(ev.target).closest('.issue').attr('name');
      $(".issue_i_" + id).removeClass('touchable');
      $(".row_i_" + id).removeClass('touchable');
    },
    'mouseover on @item_hover': function(ev) {
      var id = $(ev.target).closest('.item').attr('name');
      $(".row_i_" + id).addClass('touchable');
      $(".issue_i_" + id).addClass('touchable');
    },
    'mouseout on @item_hover': function(ev) {
      var id = $(ev.target).closest('.item').attr('name');
      $(".row_i_" + id).removeClass('touchable');
      $(".issue_i_" + id).removeClass('touchable');
    }
  }
);
