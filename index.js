(function() {
  var global, on_zoom, redraw;

  global = {
    /* constants
    */
    ZOOM: {
      characters: 64
    },
    BLOCK_BORDER: 8
  };

  redraw = function() {
    /* redraw the visualization according to the current viewport
    */
    var bbox, bottom, bottom_square, characters, codepoints, coords, i, j, left, left_square, meridians, parallels, plane_digits, right, right_square, square_coords, top, top_square, x, x_domain, y, y_domain, _i, _j, _results, _results2;
    x = global.x;
    y = global.y;
    /* convert the viewport back to domain coordinates
    */
    bbox = global.vis.node().getBoundingClientRect();
    left = Math.max(0, Math.floor(x.invert(0)));
    right = Math.min(Math.ceil(x.invert(bbox.width)), 1024);
    top = Math.max(0, Math.floor(y.invert(0)));
    bottom = Math.min(Math.ceil(y.invert(bbox.height)), 1280);
    /* redraw blocks
    */
    global.vis.selectAll('.block').attr('d', function(d) {
      var path;
      path = "M" + (x(d.x1)) + " " + (y(d.y1)) + " L" + (x(d.x2)) + " " + (y(d.y1)) + " L" + (x(d.x2)) + " " + (y(d.y2)) + " L" + (x(d.x1)) + " " + (y(d.y2)) + " z";
      /* blocks are hollow when displaying characters
      */
      if (global.zoom.scale() > global.ZOOM.characters) {
        path += " M" + (x(d.x1) + global.BLOCK_BORDER) + " " + (y(d.y1) + global.BLOCK_BORDER) + " L" + (x(d.x2) - global.BLOCK_BORDER) + " " + (y(d.y1) + global.BLOCK_BORDER) + " L" + (x(d.x2) - global.BLOCK_BORDER) + " " + (y(d.y2) - global.BLOCK_BORDER) + " L" + (x(d.x1) + global.BLOCK_BORDER) + " " + (y(d.y2) - global.BLOCK_BORDER) + " z";
      }
      return path;
    });
    /* draw gridlines: filter the obtained domains according to the current zoom
    */
    x_domain = (function() {
      _results = [];
      for (var _i = left; left <= right ? _i < right : _i > right; left <= right ? _i++ : _i--){ _results.push(_i); }
      return _results;
    }).apply(this).filter(function(d) {
      if (global.zoom.scale() <= 2) return d % 256 === 0;
      if (global.zoom.scale() <= 16) return d % 16 === 0;
      return true;
    });
    y_domain = (function() {
      _results2 = [];
      for (var _j = top; top <= bottom ? _j < bottom : _j > bottom; top <= bottom ? _j++ : _j--){ _results2.push(_j); }
      return _results2;
    }).apply(this).filter(function(d) {
      if (global.zoom.scale() <= 2) return d % 256 === 0;
      if (global.zoom.scale() <= 16) return d % 16 === 0;
      return true;
    });
    /* draw the meridians
    */
    meridians = global.vis.selectAll('.meridian').data(x_domain, function(d) {
      return d;
    });
    meridians.enter().append('line').attr('class', 'meridian').classed('world', function(d) {
      return d % 256 === 0;
    }).classed('plane', function(d) {
      return d % 16 === 0 && !(d % 256 === 0);
    });
    meridians.attr('x1', function(d) {
      return x(d);
    }).attr('y1', y(0)).attr('x2', function(d) {
      return x(d);
    }).attr('y2', function(d) {
      if (d < 256) {
        return y(1280);
      } else {
        return y(1024);
      }
    });
    meridians.exit().remove();
    /* draw the parallels
    */
    parallels = global.vis.selectAll('.parallel').data(y_domain, function(d) {
      return d;
    });
    parallels.enter().append('line').attr('class', 'parallel').classed('world', function(d) {
      return d % 256 === 0;
    }).classed('plane', function(d) {
      return d % 16 === 0 && !(d % 256 === 0);
    });
    parallels.attr('x1', x(0)).attr('y1', function(d) {
      return y(d);
    }).attr('x2', function(d) {
      if (d < 1024) {
        return x(1024);
      } else {
        return x(256);
      }
    }).attr('y2', function(d) {
      return y(d);
    });
    parallels.exit().remove();
    /* update the world's border
    */
    global.vis.selectAll('.world_border').attr('d', "M" + (x(0)) + " " + (y(0)) + " L" + (x(1024)) + " " + (y(0)) + " L" + (x(1024)) + " " + (y(1024)) + " L" + (x(256)) + " " + (y(1024)) + " L" + (x(256)) + " " + (y(1280)) + " L" + (x(0)) + " " + (y(1280)) + " z");
    /* translate the world-level digits
    */
    global.vis.selectAll('.world.digit').attr('x', function(d) {
      return x(256 * (d % 4));
    }).attr('y', function(d) {
      return y(256 * Math.floor(d / 4));
    });
    /* hide world-level digits when displaying plane-level ones
    */
    global.vis.selectAll('.world.digit').attr('display', function() {
      if (global.zoom.scale() > 6) {
        return 'none';
      } else {
        return 'display';
      }
    });
    /* draw plane-level digits
    */
    square_coords = [];
    if (global.zoom.scale() > 6 && global.zoom.scale() <= 176) {
      left_square = Math.floor(left / 16);
      right_square = Math.ceil(right / 16);
      top_square = Math.floor(top / 16);
      bottom_square = Math.ceil(bottom / 16);
      for (i = top_square; top_square <= bottom_square ? i < bottom_square : i > bottom_square; top_square <= bottom_square ? i++ : i--) {
        for (j = left_square; left_square <= right_square ? j < right_square : j > right_square; left_square <= right_square ? j++ : j--) {
          /* skip coordinates in the bottom right corner, where there are no planes
          */
          if (i < 64 || j < 16) {
            square_coords.push({
              i: i,
              j: j,
              code: (Math.floor(j / 16) + 4 * Math.floor(i / 16)) * 256 + (i % 16) * 16 + (j % 16)
            });
          }
        }
      }
    }
    plane_digits = global.vis.selectAll('.plane.digit').data(square_coords, function(d) {
      return d.code;
    });
    plane_digits.enter().append('text').attr('class', 'plane digit').text(function(d) {
      return global.three_digits_hex(d.code);
    }).attr('dx', '0.4em').attr('dy', '1.2em');
    plane_digits.attr('x', function(d) {
      return x(16 * d.j);
    }).attr('y', function(d) {
      return y(16 * d.i);
    });
    plane_digits.exit().remove();
    /* draw codepoints and characters
    */
    coords = [];
    if (global.zoom.scale() > global.ZOOM.characters) {
      for (i = top; top <= bottom ? i < bottom : i > bottom; top <= bottom ? i++ : i--) {
        for (j = left; left <= right ? j < right : j > right; left <= right ? j++ : j--) {
          /* skip coordinates in the bottom right corner, where there are no planes
          */
          if (i < 1024 || j < 256) {
            coords.push({
              i: i,
              j: j,
              code: (Math.floor(j / 256) + 4 * Math.floor(i / 256)) * 65536 + (Math.floor(i / 16) % 16) * 4096 + (Math.floor(j / 16) % 16) * 256 + (j % 16) * 16 + (i % 16)
            });
          }
        }
      }
    }
    codepoints = global.vis.selectAll('.codepoint').data((global.zoom.scale() > 176 ? coords : []), function(d) {
      return d.code;
    });
    codepoints.enter().append('text').attr('class', 'codepoint digit').text(function(d) {
      return global.five_digits_hex(d.code);
    }).attr('dy', '-0.6em');
    codepoints.attr('x', function(d) {
      return x(d.j + 0.5);
    }).attr('y', function(d) {
      return y(d.i + 1);
    });
    codepoints.exit().remove();
    characters = global.vis.selectAll('.character').data(coords, function(d) {
      return d.code;
    });
    characters.enter().append('text').attr('class', 'character').text(function(d) {
      return String.fromCodePoint(d.code);
    }).attr('dy', '0.3em');
    characters.attr('x', function(d) {
      return x(d.j + 0.5);
    }).attr('y', function(d) {
      return y(d.i + 0.5);
    }).attr('font-size', function(d) {
      return 12 * global.zoom.scale() / 64.0;
    });
    return characters.exit().remove();
    /* DEBUG print the number of elements within the vis
    */
    /* DEBUG print the current zoom scale
    */
  };

  on_zoom = function() {
    return redraw();
  };

  window.main = function() {
    /* hexadecimal formatters
    */
    var bbox, blocks;
    global.hex = d3.format('X');
    global.three_digits_hex = d3.format('03X');
    global.five_digits_hex = d3.format('05X');
    /* prepare the vis
    */
    global.vis = d3.select('body').append('svg').attr('width', '100%').attr('height', '100%');
    /* obtain the current viewport to center the chart
    */
    bbox = global.vis.node().getBoundingClientRect();
    /* scales for "meridians" and "parallels"
    */
    global.x = d3.scale.linear().domain([0, 1024]).range([bbox.width / 2 - 160, bbox.width / 2 + 160]);
    global.y = d3.scale.linear().domain([0, 1280]).range([bbox.height / 2 - 200, bbox.height / 2 + 200]);
    /* zoom behavior
    */
    global.zoom = d3.behavior.zoom().x(global.x).y(global.y).scaleExtent([1, 1024]).on('zoom', on_zoom);
    global.vis.call(global.zoom);
    /* create blocks
    */
    blocks = [
      {
        name: 'Egyptian Hieroglyphs',
        x1: 256,
        y1: 48,
        x2: 323,
        y2: 64
      }
    ];
    global.vis.selectAll('.block').data(blocks).enter().append('path').attr('class', 'block');
    /* create the world-level digits
    */
    global.vis.selectAll('.world.digit').data([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]).enter().append('text').attr('class', 'world digit').text(function(d) {
      return global.hex(d);
    }).attr('dx', '0.4em').attr('dy', '1.2em');
    /* draw Unicode's "world borders"
    */
    global.vis.append('path').attr('class', 'world_border');
    /* redraw the visualization according to the current viewport (translation + zoom)
    */
    return redraw();
  };

}).call(this);
