#

def simple_boxes(gl)
  gl.prepare!

  size = 1.0

  cube = Cube.new(size * 0.99, (1.0 * size) * 0.99, size * 0.99, 1.0)

  gl.lookat(1, 10.0, 15.0, 10.0, 1.0, 1.0, 1.0, 60.0)

  gl.main_loop { |gtdt|
    global_time, delta_time = gtdt

    gl.drawmode {
      gl.threed {
        gl.draw_grid(33, size * 2.0)
        cube.deltap(1.0, 1.0, 1.0)
        cube.draw(true)
      }

      gl.twod {
        gl.draw_fps(10, 10)
        cube.label("%08.2f" % global_time)
      }
    }

    gl.interim {
    }
  }
end
