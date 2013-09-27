### this module handles a Level Of Detail rendering of Unicode codepoints and characters, as well as a labeled grid ###

module = {}

### draw the grid within the given layer ###
module.draw = (params) ->
    module.layer = params.layer
    
    ### draw Unicode's "world borders" ###
    module.layer.append('path')
        .attr('class', 'world_border')
        .attr('d', "M0 0 L1024 0 L1024 1024 L256 1024 L256 1280 L0 1280 z")
        
    ### create the world-level digits ###
    new_digit = module.layer.selectAll('.world.digit')
        .data([0...17])
      .enter().append('text')
        .attr('class', 'world digit')
        .text((d) -> module.hex(d))
        .attr('transform', (d) -> "translate(#{256 * (d % 4)} #{256 * Math.floor(d / 4)})")
        
    module.redraw({})
    
### redraw the grid's layer-specific stuff according to the current viewport ###
module.redraw = (params) ->
    duration = if params.duration? then params.duration else 0
    easing = if params.easing? then params.easing else 'linear'
    
    ### convert the viewport back to domain coordinates ###
    bbox = index_module.vis.node().getBoundingClientRect()
    
    translate = index_module.zoom.translate()
    scale = index_module.zoom.scale()
    l = -translate[0] / scale
    t = -translate[1] / scale
    r = (bbox.width - translate[0]) / scale
    b = (bbox.height - translate[1]) / scale
    
    left = Math.max(0, Math.floor(l))
    right = Math.min(Math.ceil(r), 1024)
    top = Math.max(0, Math.floor(t))
    bottom = Math.min(Math.ceil(b), 1280)
    
    ### filter the obtained domains according to the current zoom ###
    x_domain = [left+1...right].filter (d) ->
        if index_module.zoom.scale() <= 2
            return d % 256 == 0
        if index_module.zoom.scale() <= 16
            return d % 16 == 0
            
        return true
        
    y_domain = [top+1...bottom].filter (d) ->
        if index_module.zoom.scale() <= 2
            return d % 256 == 0
        if index_module.zoom.scale() <= 16
            return d % 16 == 0
            
        return true
        
    ### draw or delete the meridians ###
    meridians = module.layer.selectAll('.meridian')
        .data(x_domain, (d) -> d)
        
    meridians.enter().insert('line', '.world_border')
        .attr('class', 'meridian')
        .classed('world', (d) -> d % 256 == 0)
        .classed('plane', (d) -> d % 16 == 0 and not (d % 256 == 0))
        
    meridians
        .attr('x1', (d) -> d )
        .attr('y1', 0)
        .attr('x2', (d) -> d )
        .attr('y2', (d) -> if d < 256 then 1280 else 1024 )
        
    meridians.exit().remove()
    
    ### draw or delete the parallels ###
    parallels = module.layer.selectAll('.parallel')
        .data(y_domain, (d) -> d)
        
    parallels.enter().insert('line', '.world_border')
        .attr('class', 'parallel')
        .classed('world', (d) -> d % 256 == 0)
        .classed('plane', (d) -> d % 16 == 0 and not (d % 256 == 0))
        
    parallels
        .attr('x1', 0)
        .attr('y1', (d) -> d )
        .attr('x2', (d) -> if d < 1024 then 1024 else 256 )
        .attr('y2', (d) -> d )
        
    parallels.exit().remove()
    
    ### keep grid borders 1-pixel thin ###
    meridians
      .transition().duration(duration).ease(easing)
        .attr('stroke-width', 1/scale)
    parallels
      .transition().duration(duration).ease(easing)
        .attr('stroke-width', 1/scale)
        
    ### keep world borders 3-pixel thin ###
    module.layer.select('.world_border')
      .transition().duration(duration).ease(easing)
        .attr('stroke-width', 3.0/scale)
        
    ### ------ ###
    ### DIGITS ###
    ### ------ ###
    
    ### scale the world-level digits ###
    module.layer.selectAll('.world.digit')
      .transition().duration(duration).ease(easing)
        .attr('font-size', 12.0/scale)
        .attr('dx', 6.0/scale)
        .attr('dy', 16.0/scale)
        
    ### hide world-level digits when displaying plane-level ones ###
    module.layer.selectAll('.world.digit')
        .attr('display', () -> if scale > index_module.ZOOM.plane_level then 'none' else 'display')
        
    ### draw or delete plane-level digits ###
    square_coords = []
    
    if scale > index_module.ZOOM.plane_level and scale <= index_module.ZOOM.codepoints
        left_square = Math.floor(left / 16)
        right_square = Math.ceil(right / 16)
        top_square = Math.floor(top / 16)
        bottom_square = Math.ceil(bottom / 16)
        
        for i in [top_square...bottom_square]
            for j in [left_square...right_square]
                # skip coordinates in the bottom right corner, where there are no planes ###
                if i < 64 or j < 16
                    square_coords.push
                        i: i
                        j: j
                        code: (Math.floor(j / 16) + 4 * Math.floor(i / 16))*256 + (i % 16)*16 + (j % 16)
                        
    plane_digits = module.layer.selectAll('.plane.digit')
        .data(square_coords, (d) -> d.code)
        
    plane_digits
      .enter().append('text')
        .attr('class', 'plane digit')
        .text((d) -> module.three_digits_hex(d.code))
        
    plane_digits
        .attr('x', (d) -> 16 * d.j)
        .attr('y', (d) -> 16 * d.i)
        
    plane_digits.exit().remove()
    
    ### scale the plane-level digits ###
    plane_digits
      .transition().duration(duration).ease(easing)
        .attr('font-size', 12.0/scale)
        .attr('dx', 6.0/scale)
        .attr('dy', 16.0/scale)
        
    ### ---------- ###
    ### CODEPOINTS ###
    ### ---------- ###
    
    ### draw or delete codepoints ###
    coords = []
    
    if scale > index_module.ZOOM.characters
        for i in [top...bottom]
            for j in [left...right]
                ### skip coordinates in the bottom right corner, where there are no planes ###
                if i < 1024 or j < 256
                    coords.push
                        i: i
                        j: j
                        code: ((Math.floor(j / 256) + 4 * Math.floor(i / 256)))*65536 + (Math.floor(i / 16) % 16)*4096 + (Math.floor(j / 16) % 16)*256 + (j % 16)*16 + (i % 16)
                        
    codepoints = module.layer.selectAll('.codepoint')
        .data((if scale > index_module.ZOOM.codepoints then coords else []), (d) -> d.code)
        
    codepoints
      .enter().append('text')
        .attr('class', 'codepoint digit')
        .text((d) -> module.five_digits_hex(d.code))
        
    codepoints
        .attr('x', (d) -> d.j + 0.5)
        .attr('y', (d) -> d.i + 1)
        
    codepoints.exit()
      .transition().delay(duration)
        .remove()
    
    ### scale codepoints ###
    codepoints
      .transition().duration(duration).ease(easing)
        .attr('font-size', 9.0/scale)
        .attr('dy', -4.0/scale)
        
    ### ---------- ###
    ### CHARACTERS ###
    ### ---------- ###
    
    ### draw or delete characters ###
    characters = module.layer.selectAll('.character')
        .data(coords, (d) -> d.code)
        
    characters
      .enter().append('text')
        .attr('class', 'character')
        .text((d) -> String.fromCodePoint(d.code))
        
    characters
        .attr('x', (d) -> d.j + 0.5)
        .attr('y', (d) -> d.i + 0.7)
        
    characters.exit()
      .transition().delay(duration)
        .remove()
        
    ### scale characters ###
    characters
      .transition().duration(duration).ease(easing)
        .attr('font-size', 16.0/index_module.ZOOM.characters)
        
### hexadecimal formatters ###
module.hex = d3.format('X')
module.three_digits_hex = d3.format('03X')
module.five_digits_hex = d3.format('05X')

window.gridchars_module = module
