// simple mruby/raylib game

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>


#include <mruby.h>
#include <mruby/array.h>
#include <mruby/irep.h>
#include <mruby/compile.h>
#include <mruby/string.h>
#include <mruby/error.h>
#include <mruby/data.h>
#include <mruby/class.h>
#include <mruby/value.h>
#include <mruby/variable.h>


#include <raylib.h>
#include <raymath.h>


#include "init.h"


static void if_exception_error_and_exit(mrb_state* mrb, char *context) {
  // check for exception, only one can exist at any point in time
  if (mrb->exc) {
    fprintf(stderr, "Exception in %s", context);
    mrb_print_error(mrb);
    exit(2);
  }
}


static void eval_static_libs(mrb_state* mrb, ...) {
  va_list argp;
  va_start(argp, mrb);

  int end_of_static_libs = 0;
  uint8_t const *p;

  while(!end_of_static_libs) {
    p = va_arg(argp, uint8_t const*);
    if (NULL == p) {
      end_of_static_libs = 1;
    } else {
      mrb_load_irep(mrb, p);
      if_exception_error_and_exit(mrb, "Exception in bundled ruby\n");
    }
  }

  va_end(argp);
}


typedef struct {
  Camera camera;
  RenderTexture2D buffer_target;
  Vector2 mousePosition;
} play_data_s;


typedef struct {
  float angle;
  Vector3 position;
  Vector3 rotation;
  Vector3 scale;
  Model model;
  Texture2D texture;
} model_data_s;


// Garbage collector handler, for play_data struct
// if play_data contains other dynamic data, free it too!
// Check it with GC.start
static void play_data_destructor(mrb_state *mrb, void *p_) {
  play_data_s *pd = (play_data_s *)p_;

  UnloadRenderTexture(pd->buffer_target);     // Unload texture

  mrb_free(mrb, pd);
};


static void model_data_destructor(mrb_state *mrb, void *p_) {
  model_data_s *pd = (model_data_s *)p_;

  // De-Initialization
  UnloadTexture(pd->texture);     // Unload texture
  UnloadModel(pd->model);         // Unload model

  mrb_free(mrb, pd);
};


const struct mrb_data_type play_data_type = {"play_data", play_data_destructor};
const struct mrb_data_type model_data_type = {"model_data", model_data_destructor};


static mrb_value mousep(mrb_state* mrb, mrb_value self)
{
  mrb_value block;
  mrb_get_args(mrb, "&", &block);

  play_data_s *p_data = NULL;
  mrb_value data_value; // this IV holds the data

  data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@pointer"));

  Data_Get_Struct(mrb, data_value, &play_data_type, p_data);
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }

  mrb_value mousexy = mrb_ary_new(mrb);

  mrb_ary_set(mrb, mousexy, 0, mrb_float_value(mrb, p_data->mousePosition.x));
  mrb_ary_set(mrb, mousexy, 1, mrb_float_value(mrb, p_data->mousePosition.y));

  return mrb_yield_argv(mrb, block, 2, &mousexy);
}


static mrb_value model_init(mrb_state* mrb, mrb_value self)
{
  mrb_value model_obj = mrb_nil_value();
  mrb_value model_png = mrb_nil_value();
  mrb_float scalef;
  mrb_get_args(mrb, "oof", &model_obj, &model_png, &scalef);

  char *c_model_obj = RSTRING_PTR(model_obj);
  char *c_model_png = RSTRING_PTR(model_png);

  model_data_s *p_data;

  p_data = malloc(sizeof(model_data_s));
  memset(p_data, 0, sizeof(model_data_s));
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not allocate Model");
  }

  p_data->model = LoadModel(c_model_obj); // Load OBJ model

  p_data->position.x = 0.0f;
  p_data->position.y = 0.0f;
  p_data->position.z = 0.0f;

  p_data->rotation.x = 0.0f;
  p_data->rotation.y = 1.0f;
  p_data->rotation.z = 0.0f; // Set model position
  p_data->angle = 0.0;
  
  p_data->texture = LoadTexture(c_model_png); // Load model texture
  p_data->model.material.maps[MAP_DIFFUSE].texture = p_data->texture; // Set map diffuse texture

  //TODO?
  //p_data->model.material.shader = shader;

  p_data->scale.x = scalef;
  p_data->scale.y = scalef;
  p_data->scale.z = scalef;

  mrb_iv_set(
      mrb, self, mrb_intern_lit(mrb, "@pointer"),
      mrb_obj_value(
          Data_Wrap_Struct(mrb, mrb->object_class, &model_data_type, p_data)));

  return self;
}


static mrb_value draw_model(mrb_state* mrb, mrb_value self)
{
  model_data_s *p_data = NULL;
  mrb_value data_value; // this IV holds the data

  data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@pointer"));

  Data_Get_Struct(mrb, data_value, &model_data_type, p_data);
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }

  // Draw 3d model with texture
  DrawModelEx(p_data->model, p_data->position, p_data->rotation, p_data->angle, p_data->scale, WHITE);
  //DrawModelWiresEx(p_data->model, p_data->position, p_data->rotation, p_data->angle, p_data->scale, BLACK);   // Draw 3d model with texture

  return mrb_nil_value();
}


static mrb_value game_init(mrb_state* mrb, mrb_value self)
{
  // Initialization
  mrb_value game_name = mrb_nil_value();
  mrb_int screenWidth,screenHeight,screenFps;

  mrb_get_args(mrb, "oiii", &game_name, &screenWidth, &screenHeight, &screenFps);

  char *c_game_name = RSTRING_PTR(game_name);

  SetConfigFlags(FLAG_MSAA_4X_HINT);

  InitWindow(screenWidth, screenHeight, c_game_name);

  play_data_s *p_data;

  p_data = malloc(sizeof(play_data_s));
  memset(p_data, 0, sizeof(play_data_s));
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not allocate @data");
  }

  // Define the camera to look into our 3d world
  p_data->camera.position = (Vector3){ 0.0f, 3.0f, -0.25f };    // Camera position
  p_data->camera.target = (Vector3){ 0.0f, 0.0f, 0.0f };      // Camera looking at point
  p_data->camera.up = (Vector3){ 0.0f, 1.0f, 0.0f };          // Camera up vector (rotation towards target)
  p_data->camera.fovy = 33.0f;                                // Camera field-of-view Y
  //p_data->camera.type = CAMERA_PERSPECTIVE;                   // Camera mode type
  p_data->camera.type = CAMERA_ORTHOGRAPHIC;                   // Camera mode type
  //SetCameraMode(p_data->camera, CAMERA_ORBITAL);
  //SetCameraMode(p_data->camera, CAMERA_THIRD_PERSON);

  p_data->buffer_target = LoadRenderTexture(screenWidth, screenHeight);

  mrb_iv_set(
      mrb, self, mrb_intern_lit(mrb, "@pointer"), // set @data
      mrb_obj_value(                           // with value hold in struct
          Data_Wrap_Struct(mrb, mrb->object_class, &play_data_type, p_data)));

  SetTargetFPS(screenFps);

  return self;
}


static mrb_value deltap_model(mrb_state* mrb, mrb_value self)
{
  mrb_float x,y,z;

  mrb_get_args(mrb, "fff", &x, &y, &z);

  model_data_s *p_data = NULL;
  mrb_value data_value; // this IV holds the data

  data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@pointer"));

  Data_Get_Struct(mrb, data_value, &model_data_type, p_data);
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }

  p_data->position.x = x;
  p_data->position.y = y;
  p_data->position.z = z;

  return mrb_nil_value();
}

static mrb_value deltar_model(mrb_state* mrb, mrb_value self)
{
  mrb_float x,y,z,r;

  mrb_get_args(mrb, "ffff", &x, &y, &z, &r);

  model_data_s *p_data = NULL;
  mrb_value data_value; // this IV holds the data

  data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@pointer"));

  Data_Get_Struct(mrb, data_value, &model_data_type, p_data);
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }

  p_data->rotation.x = x;
  p_data->rotation.y = y;
  p_data->rotation.z = z;
  p_data->angle = r;

  return mrb_nil_value();
}

static mrb_value yawpitchroll_model(mrb_state* mrb, mrb_value self)
{
  mrb_float yaw,pitch,roll;

  mrb_get_args(mrb, "fff", &yaw, &pitch, &roll);

  model_data_s *p_data = NULL;
  mrb_value data_value; // this IV holds the data

  data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@pointer"));

  Data_Get_Struct(mrb, data_value, &model_data_type, p_data);
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }

  Matrix transform = MatrixIdentity();

  transform = MatrixMultiply(transform, MatrixRotateZ(DEG2RAD*roll));
  transform = MatrixMultiply(transform, MatrixRotateX(DEG2RAD*pitch));
  transform = MatrixMultiply(transform, MatrixRotateY(DEG2RAD*yaw));

  p_data->model.transform = transform;

  return mrb_nil_value();
}


static mrb_value draw_grid(mrb_state* mrb, mrb_value self)
{
  mrb_int a;
  mrb_float b;

  mrb_get_args(mrb, "if", &a, &b);

  DrawGrid(a, b);

  return mrb_nil_value();
}


//TODO: this
//DrawGizmo(position);        // Draw gizmo


static mrb_value main_loop(mrb_state* mrb, mrb_value self)
{
  mrb_value block;
  mrb_get_args(mrb, "&", &block);

  fprintf(stderr, "Before block\n");

  play_data_s *p_data = NULL;
  mrb_value data_value;     // this IV holds the data
  data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@pointer"));

  Data_Get_Struct(mrb, data_value, &play_data_type, p_data);
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }

  Shader shader = LoadShader("resources/shaders/glsl330/base.vs",
                             "resources/shaders/glsl330/pixelizer.fs");
                             //"resources/shaders/glsl330/depth.fs");
                             //"resources/shaders/glsl330/base.fs");

  DisableCursor();

  // Main game loop
  while (!WindowShouldClose()) // Detect window close button or ESC key
  {
    p_data->mousePosition = GetMousePosition();

    UpdateCamera(&p_data->camera);

    BeginDrawing();

    ClearBackground(BLACK);

    if (IsKeyPressed(KEY_RIGHT)) {

      BeginTextureMode(p_data->buffer_target); // Enable drawing to texture

      BeginMode3D(p_data->camera);

      mrb_yield_argv(mrb, block, 0, MRB_ARGS_NONE());

      EndMode3D();

      EndTextureMode();

      BeginShaderMode(shader);

      DrawTextureRec(
                      p_data->buffer_target.texture, 
                      (Rectangle){ 0, 0, p_data->buffer_target.texture.width, -p_data->buffer_target.texture.height },
                      (Vector2){ 0, 0 },
                      WHITE
                    );

      EndShaderMode();

    } else {
      BeginMode3D(p_data->camera);

      mrb_yield_argv(mrb, block, 0, MRB_ARGS_NONE());

      EndMode3D();
    }

    EndDrawing();
  }

  CloseWindow(); // Close window and OpenGL context

  fprintf(stderr, "After block\n");

  return mrb_nil_value();
}


int main(int argc, char** argv) {
  mrb_state *mrb;
  mrb_value ret;

  // initialize mruby
  if (!(mrb = mrb_open())) {
    fprintf(stderr,"%s: could not initialize mruby\n",argv[0]);
    return -1;
  }

  mrb_value args = mrb_ary_new(mrb);
  int i;

  // convert argv into mruby strings
  for (i=1; i<argc; i++) {
     mrb_ary_push(mrb, args, mrb_str_new_cstr(mrb,argv[i]));
  }

  mrb_define_global_const(mrb, "ARGV", args);

  struct RClass *game_class = mrb_define_class(mrb, "GameLoop", mrb->object_class);
  mrb_define_method(mrb, game_class, "initialize", game_init, MRB_ARGS_NONE());
  mrb_define_method(mrb, game_class, "main_loop", main_loop, MRB_ARGS_BLOCK());
  mrb_define_method(mrb, game_class, "draw_grid", draw_grid, MRB_ARGS_REQ(2));
  mrb_define_method(mrb, game_class, "mousep", mousep, MRB_ARGS_BLOCK());

  struct RClass *model_class = mrb_define_class(mrb, "Model", mrb->object_class);
  mrb_define_method(mrb, model_class, "initialize", model_init, MRB_ARGS_REQ(2));
  mrb_define_method(mrb, model_class, "draw", draw_model, MRB_ARGS_NONE());
  mrb_define_method(mrb, model_class, "deltap", deltap_model, MRB_ARGS_REQ(3));
  mrb_define_method(mrb, model_class, "deltar", deltar_model, MRB_ARGS_REQ(4));
  mrb_define_method(mrb, model_class, "yawpitchroll", yawpitchroll_model, MRB_ARGS_REQ(3));

  eval_static_libs(mrb, init, NULL);

  mrb_close(mrb);

  fprintf(stderr, "exiting ... \n");

  return 0;
}
