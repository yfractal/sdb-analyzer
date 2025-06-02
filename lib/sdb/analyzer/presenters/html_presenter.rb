require 'erb'

module Sdb
  module Analyzer
    module Presenters
      class HtmlPresenter
        CANVAS_WIDTH = 1000  # pixels
        CANVAS_HEIGHT = 6000  # pixels
        BAR_HEIGHT = 30      # pixels

        def initialize(roots)
          @roots = roots
          @total_duration = @roots.map(&:duration).sum.to_f
          @start_time = @roots.map(&:ts).min
          @max_depth = 200
        end

        def render(file_name)
          template = ERB.new(html_template)
          frames = collect_frames(@roots)

          File.write(file_name, template.result(binding))
        end

        private

        def collect_frames(roots)
          frames = []
          current_y = CANVAS_HEIGHT - BAR_HEIGHT # Start from bottom

          roots.each do |root|
            collect_frame_data(root, nil, frames, current_y, @max_depth)
            current_y -= BAR_HEIGHT
          end

          frames
        end

        def collect_frame_data(iseq_node, parent_node, frames, y_position, max_depth)
          return if max_depth == 0
          return if iseq_node.duration == 0

          duration = iseq_node.duration
          start_offset = (iseq_node.ts - @start_time)

          # Calculate bar dimensions
          width = (duration / @total_duration * CANVAS_WIDTH).round
          x_pos = (start_offset / @total_duration * CANVAS_WIDTH).round

          # Calculate percentage of parent's duration
          parent_percentage = parent_node ? (duration.to_f / parent_node.duration * 100).round(2) : 100
          puts "iseq_node: #{iseq_node.iseq.name}, duration: #{duration}, parent_percentage: #{parent_percentage}"

          # Generate label
          method = iseq_node.iseq.name || iseq_node.iseq.addr.to_s
          file = iseq_node.iseq.path_or_module || ""
          line_no = iseq_node.iseq.first_lineno || 0

          if file.include?("/") && !file.split("/")[-3..-1].nil?
            file_path = file.split("/")[-3..-1].join("/")
          else
            file_path = file
          end

          frames << {
            x: x_pos,
            y: y_position,
            width: width,
            height: BAR_HEIGHT,
            method: method,
            file: file_path,
            line: line_no,
            duration_ms: duration / 1000.0,
            percentage: parent_percentage,
            color: percentage_to_color(parent_percentage)
          }
          # puts "frames: #{frames.inspect}"

          if iseq_node.children.any?
            y_position -= BAR_HEIGHT

            iseq_node.children.each do |child|
              collect_frame_data(child, iseq_node, frames, y_position, max_depth - 1)
            end
          end
        end

        def percentage_to_color(percentage)
          if percentage >= 80
            '#FF4500'  # Red-Orange for hot spots
          elsif percentage >= 60
            '#FFA500'  # Orange
          elsif percentage >= 40
            '#FFD700'  # Gold
          elsif percentage >= 20
            '#98FB98'  # Pale Green
          else
            '#87CEEB'  # Sky Blue
          end
        end

        def html_template
          <<~HTML
            <!DOCTYPE html>
            <html>
            <head>
              <title>Ruby Profile Flame Graph</title>
              <style>
                body {
                  margin: 0;
                  padding: 20px;
                  font-family: Arial, sans-serif;
                  background-color: #FFFAF0;
                }
                #canvas {
                  border: 1px solid #ccc;
                  background-color: white;
                }
                #tooltip {
                  position: absolute;
                  display: none;
                  background-color: rgba(0, 0, 0, 0.8);
                  color: white;
                  padding: 10px;
                  border-radius: 4px;
                  font-size: 14px;
                  pointer-events: none;
                }
              </style>
            </head>
            <body>
              <canvas id="canvas" width="<%= CANVAS_WIDTH %>" height="<%= CANVAS_HEIGHT %>"></canvas>
              <div id="tooltip"></div>

              <script>
                const canvas = document.getElementById('canvas');
                const ctx = canvas.getContext('2d');
                const tooltip = document.getElementById('tooltip');

                // Frame data from Ruby
                const frames = <%= frames.to_json %>;

                function drawFrame(frame) {
                  ctx.fillStyle = frame.color;
                  ctx.fillRect(frame.x, frame.y, frame.width, frame.height);

                  ctx.strokeStyle = 'rgba(0, 0, 0, 0.3)';
                  ctx.strokeRect(frame.x, frame.y, frame.width, frame.height);

                  // Draw text
                  ctx.save();
                  ctx.fillStyle = 'black';
                  ctx.font = '10px Arial';
                  ctx.textBaseline = 'middle';

                  // Calculate available width for text
                  const padding = 4;
                  const maxWidth = frame.width - (padding * 2);

                  if (maxWidth > 30) { // Only draw text if there's enough space
                    // Prepare text
                    const label = `${frame.method} (${frame.duration_ms.toFixed(1)}ms)`;

                    // Measure and truncate text if needed
                    let metrics = ctx.measureText(label);
                    let displayText = label;
                    if (metrics.width > maxWidth) {
                      // Try with just the method name
                      displayText = frame.method;
                      metrics = ctx.measureText(displayText);
                      if (metrics.width > maxWidth) {
                        // Truncate with ellipsis if still too long
                        while (metrics.width > maxWidth && displayText.length > 3) {
                          displayText = displayText.slice(0, -1);
                          metrics = ctx.measureText(displayText + '...');
                        }
                        displayText += '...';
                      }
                    }

                    // Draw the text centered in the box
                    const textX = frame.x + padding;
                    const textY = frame.y + (frame.height / 2);
                    ctx.fillText(displayText, textX, textY, maxWidth);
                  }

                  ctx.restore();
                }

                function drawAllFrames() {
                  ctx.clearRect(0, 0, canvas.width, canvas.height);
                  frames.forEach(drawFrame);
                }

                function showTooltip(frame, event) {
                  const text = `${frame.method}
                    ${frame.file}:${frame.line}`;

                  tooltip.textContent = text;
                  tooltip.style.display = 'block';
                  tooltip.style.left = (event.pageX + 10) + 'px';
                  tooltip.style.top = (event.pageY + 10) + 'px';
                }

                function hideTooltip() {
                  tooltip.style.display = 'none';
                }

                function getFrameAtPosition(x, y) {
                  return frames.find(frame =>
                    x >= frame.x && x <= frame.x + frame.width &&
                    y >= frame.y && y <= frame.y + frame.height
                  );
                }

                canvas.addEventListener('mousemove', (event) => {
                  const rect = canvas.getBoundingClientRect();
                  const x = event.clientX - rect.left;
                  const y = event.clientY - rect.top;

                  const frame = getFrameAtPosition(x, y);
                  if (frame) {
                    showTooltip(frame, event);
                    canvas.style.cursor = 'pointer';
                  } else {
                    hideTooltip();
                    canvas.style.cursor = 'default';
                  }
                });

                canvas.addEventListener('mouseout', hideTooltip);

                // Initial render
                drawAllFrames();
              </script>
            </body>
            </html>
          HTML
        end
      end
    end
  end
end
