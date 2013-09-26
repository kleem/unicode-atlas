global = {
    ### constants ###
    ZOOM: {
        characters: 64
    },
    BLOCK_BORDER: 8
}

redraw = () ->
    ### redraw the visualization according to the current viewport ###
    x = global.x
    y = global.y
    
    ### convert the viewport back to domain coordinates ###
    bbox = global.vis.node().getBoundingClientRect()
    
    left = Math.max(0, Math.floor(x.invert(0)))
    right = Math.min(Math.ceil(x.invert(bbox.width)), 1024)
    top = Math.max(0, Math.floor(y.invert(0)))
    bottom = Math.min(Math.ceil(y.invert(bbox.height)), 1280)
    
    ### redraw blocks ###
    global.vis.selectAll('.block')
        .attr('d', global.path_generator)
        
    ### draw gridlines: filter the obtained domains according to the current zoom ###
    x_domain = [left...right].filter (d) ->
        if global.zoom.scale() <= 2
            return d % 256 == 0
        if global.zoom.scale() <= 16
            return d % 16 == 0
            
        return true
        
    y_domain = [top...bottom].filter (d) ->
        if global.zoom.scale() <= 2
            return d % 256 == 0
        if global.zoom.scale() <= 16
            return d % 16 == 0
            
        return true
        
    ### draw the meridians ###
    meridians = global.vis.selectAll('.meridian')
        .data(x_domain, (d) -> d)
        
    meridians.enter().append('line')
        .attr('class', 'meridian')
        .classed('world', (d) -> d % 256 == 0)
        .classed('plane', (d) -> d % 16 == 0 and not (d % 256 == 0))
        
    meridians
        .attr('x1', (d) -> x(d) )
        .attr('y1', y(0))
        .attr('x2', (d) -> x(d) )
        .attr('y2', (d) -> if d < 256 then y(1280) else y(1024) )
        
    meridians.exit().remove()
    
    ### draw the parallels ###
    parallels = global.vis.selectAll('.parallel')
        .data(y_domain, (d) -> d)
        
    parallels.enter().append('line')
        .attr('class', 'parallel')
        .classed('world', (d) -> d % 256 == 0)
        .classed('plane', (d) -> d % 16 == 0 and not (d % 256 == 0))
        
    parallels
        .attr('x1', x(0))
        .attr('y1', (d) -> y(d) )
        .attr('x2', (d) -> if d < 1024 then x(1024) else x(256) )
        .attr('y2', (d) -> y(d) )
        
    parallels.exit().remove()
    
    ### update the world's border ###
    global.vis.selectAll('.world_border')
        .attr('d', "M#{x(0)} #{y(0)} L#{x(1024)} #{y(0)} L#{x(1024)} #{y(1024)} L#{x(256)} #{y(1024)} L#{x(256)} #{y(1280)} L#{x(0)} #{y(1280)} z")
        
    ### translate the world-level digits ###
    global.vis.selectAll('.world.digit')
        .attr('x', (d) -> x(256 * (d % 4)))
        .attr('y', (d) -> y(256 * Math.floor(d / 4)))
        
    ### hide world-level digits when displaying plane-level ones ###
    global.vis.selectAll('.world.digit')
        .attr('display', () -> if global.zoom.scale() > 6 then 'none' else 'display')
        
    ### draw plane-level digits ###
    square_coords = []
    
    if global.zoom.scale() > 6 and global.zoom.scale() <= 176
        left_square = Math.floor(left / 16)
        right_square = Math.ceil(right / 16)
        top_square = Math.floor(top / 16)
        bottom_square = Math.ceil(bottom / 16)
        
        for i in [top_square...bottom_square]
            for j in [left_square...right_square]
                ### skip coordinates in the bottom right corner, where there are no planes ###
                if i < 64 or j < 16
                    square_coords.push
                        i: i
                        j: j
                        code: (Math.floor(j / 16) + 4 * Math.floor(i / 16))*256 + (i % 16)*16 + (j % 16)
                        
    plane_digits = global.vis.selectAll('.plane.digit')
        .data(square_coords, (d) -> d.code)
        
    plane_digits
      .enter().append('text')
        .attr('class', 'plane digit')
        .text((d) -> global.three_digits_hex(d.code))
        .attr('dx', '0.4em')
        .attr('dy', '1.2em')
        
    plane_digits
        .attr('x', (d) -> x(16 * d.j))
        .attr('y', (d) -> y(16 * d.i))
        
    plane_digits.exit().remove()
    
    ### draw codepoints and characters ###
    coords = []
    
    if global.zoom.scale() > global.ZOOM.characters
        for i in [top...bottom]
            for j in [left...right]
                ### skip coordinates in the bottom right corner, where there are no planes ###
                if i < 1024 or j < 256
                    coords.push
                        i: i
                        j: j
                        code: ((Math.floor(j / 256) + 4 * Math.floor(i / 256)))*65536 + (Math.floor(i / 16) % 16)*4096 + (Math.floor(j / 16) % 16)*256 + (j % 16)*16 + (i % 16)
                        
    codepoints = global.vis.selectAll('.codepoint')
        .data((if global.zoom.scale() > 176 then coords else []), (d) -> d.code)
        
    codepoints
      .enter().append('text')
        .attr('class', 'codepoint digit')
        .text((d) -> global.five_digits_hex(d.code))
        .attr('dy', '-0.6em')
        
    codepoints
        .attr('x', (d) -> x(d.j + 0.5))
        .attr('y', (d) -> y(d.i + 1))
        
    codepoints.exit().remove()
    
    characters = global.vis.selectAll('.character')
        .data(coords, (d) -> d.code)
        
    characters
      .enter().append('text')
        .attr('class', 'character')
        .text((d) -> String.fromCodePoint(d.code))
        .attr('dy', '0.3em')
        
    characters
        .attr('x', (d) -> x(d.j + 0.5))
        .attr('y', (d) -> y(d.i + 0.5))
        .attr('font-size', (d) -> 12 * global.zoom.scale() / 64.0)
        
    characters.exit().remove()
    
    ### DEBUG print the number of elements within the vis ###
    # console.log(global.vis.selectAll('.meridian, .parallel, .digit, .character').size())
    
    ### DEBUG print the current zoom scale ###
    # console.log(global.zoom.scale())
    
on_zoom = () ->
    redraw()
    
window.main = () ->
    ### hexadecimal formatters ###
    global.hex = d3.format('X')
    global.three_digits_hex = d3.format('03X')
    global.five_digits_hex = d3.format('05X')
    
    ### prepare the vis ###
    global.vis = d3.select('body').append('svg')
        .attr('width', '100%')
        .attr('height', '100%')
        
    ### obtain the current viewport to center the chart ###
    bbox = global.vis.node().getBoundingClientRect()
    
    ### scales for the whole drawing ###
    global.x = d3.scale.linear()
        .domain([0, 1024])
        .range([bbox.width/2-160, bbox.width/2+160])
        
    global.y = d3.scale.linear()
        .domain([0, 1280])
        .range([bbox.height/2-200, bbox.height/2+200])
        
    ### zoom behavior ###
    global.zoom = d3.behavior.zoom()
        .x(global.x)
        .y(global.y)
        .scaleExtent([1, 1024])
        .on('zoom', on_zoom)
        
    global.vis.call(global.zoom)
    
    ### create blocks ###
    
    ### custom projection that flips the y axis. see http://bl.ocks.org/mbostock/5663666 for reference ###
    ### for a projection that uses quantitative scales, see http://bl.ocks.org/mbostock/6216797 ###
    global.path_generator = d3.geo.path()
        .projection d3.geo.transform({point: (x,y) -> this.stream.point(global.x(x),global.y(-y)) })
        
    d3.json 'vis/data/Blocks.topo.json', (error, data) ->
        blocks = topojson.feature(data, data.objects.Blocks)
        
        global.vis.selectAll('.block')
            .data(blocks.features)
          .enter().append('path')
            .attr('class', 'block')
            .attr('d', global.path_generator)
          .append('title')
            .text((d) -> d.properties.name)
            
    ### create the world-level digits ###
    global.vis.selectAll('.world.digit')
        .data([0...17])
      .enter().append('text')
        .attr('class', 'world digit')
        .text((d) -> global.hex(d))
        .attr('dx', '0.4em')
        .attr('dy', '1.2em')
        
    ### draw Unicode's "world borders" ###
    global.vis.append('path')
        .attr('class', 'world_border')
        
    ### redraw the visualization according to the current viewport (translation + zoom) ###
    redraw()
    