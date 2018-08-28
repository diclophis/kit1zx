// simple mruby/raylib game

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>


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

#ifdef PLATFORM_WEB
  #include <emscripten/emscripten.h>
#endif

#include "shmup.h"
#include "snake.h"
#include "kube.h"
#include "box.h"
#include "init.h"


#define FLT_MAX 3.40282347E+38F


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
  Color color;
  Color label_color;
} model_data_s;


//TODO???????
static mrb_state *global_mrb;
static play_data_s *global_p_data = NULL;
static mrb_value global_data_value;     // this IV holds the data
static mrb_value global_block;
static int counter = 0;


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

  mrb_value mousexyz = mrb_ary_new(mrb);

  RayHitInfo nearestHit;
  char *hitObjectName = "None";
  nearestHit.distance = FLT_MAX;
  nearestHit.hit = false;
  Color cursorColor = WHITE;

  Ray ray; // Picking ray

  ray = GetMouseRay(p_data->mousePosition, p_data->camera);

  // Check ray collision aginst ground plane
  RayHitInfo groundHitInfo = GetCollisionRayGround(ray, 0.0f);

  if ((groundHitInfo.hit) && (groundHitInfo.distance < nearestHit.distance))
  {
    nearestHit = groundHitInfo;

    mrb_ary_set(mrb, mousexyz, 0, mrb_float_value(mrb, nearestHit.position.x));
    mrb_ary_set(mrb, mousexyz, 1, mrb_float_value(mrb, nearestHit.position.y));
    mrb_ary_set(mrb, mousexyz, 2, mrb_float_value(mrb, nearestHit.position.z));

    return mrb_yield_argv(mrb, block, 3, &mousexyz);
  } else {
    return mrb_nil_value();
  }
}


static mrb_value keyspressed(mrb_state* mrb, mrb_value self)
{
  mrb_int argc;
  mrb_value *checkkeys;
  mrb_get_args(mrb, "*", &checkkeys, &argc);

  play_data_s *p_data = NULL;
  mrb_value data_value; // this IV holds the data

  data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@pointer"));

  Data_Get_Struct(mrb, data_value, &play_data_type, p_data);
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }

  mrb_value pressedkeys = mrb_ary_new(mrb);
  int rc = 0;

  for (int i=0; i<argc; i++) {
    mrb_value key_to_check = checkkeys[i];

    if (IsKeyDown(mrb_int(mrb, key_to_check))) {
      mrb_ary_set(mrb, pressedkeys, rc, key_to_check);
      rc++;
    }
  }

  return pressedkeys;
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

static mrb_value cube_init(mrb_state* mrb, mrb_value self)
{
  mrb_float w,h,l,scalef;
  mrb_get_args(mrb, "ffff", &w, &h, &l, &scalef);

  model_data_s *p_data;

  p_data = malloc(sizeof(model_data_s));
  memset(p_data, 0, sizeof(model_data_s));
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not allocate Cube");
  }

  p_data->model = LoadModelFromMesh(GenMeshCube(w, h, l));

  p_data->position.x = 0.0f;
  p_data->position.y = 0.0f;
  p_data->position.z = 0.0f;

  p_data->rotation.x = 0.0f;
  p_data->rotation.y = 1.0f;
  p_data->rotation.z = 0.0f; // Set model position
  p_data->angle = 0.0;
  
  p_data->scale.x = scalef;
  p_data->scale.y = scalef;
  p_data->scale.z = scalef;

  float colors = 64.0;
  float freq = 32.0 / colors;

  int r = (sin(freq * abs(counter) + 0.0) * (127.0) + 128.0);
  int g = (sin(freq * abs(counter) + 1.0) * (127.0) + 128.0);
  int b = (sin(freq * abs(counter) + 3.0) * (127.0) + 128.0);

  counter++;

  if (counter == colors) {
    counter *= -1;
  }

  p_data->color.r = r;
  p_data->color.g = g;
  p_data->color.b = b;
  p_data->color.a = 255;

  p_data->label_color.r = r;
  p_data->label_color.g = g;
  p_data->label_color.b = b;
  p_data->label_color.a = 255;

  mrb_iv_set(
      mrb, self, mrb_intern_lit(mrb, "@pointer"),
      mrb_obj_value(
          Data_Wrap_Struct(mrb, mrb->object_class, &model_data_type, p_data)));

  return self;
}


static mrb_value sphere_init(mrb_state* mrb, mrb_value self)
{
  mrb_float ra,scalef;
  mrb_int ri,sl;
  mrb_get_args(mrb, "fiif", &ra, &ri, &sl, &scalef);

  model_data_s *p_data;

  p_data = malloc(sizeof(model_data_s));
  memset(p_data, 0, sizeof(model_data_s));
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not allocate Sphere");
  }

  p_data->model = LoadModelFromMesh(GenMeshSphere(ra, ri, sl));

  p_data->position.x = 0.0f;
  p_data->position.y = 0.0f;
  p_data->position.z = 0.0f;

  p_data->rotation.x = 0.0f;
  p_data->rotation.y = 1.0f;
  p_data->rotation.z = 0.0f; // Set model position
  p_data->angle = 0.0;
  
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
  mrb_bool draw_wires;

  mrb_get_args(mrb, "b", &draw_wires);

  model_data_s *p_data = NULL;
  mrb_value data_value; // this IV holds the data

  data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@pointer"));

  Data_Get_Struct(mrb, data_value, &model_data_type, p_data);
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }

  // Draw 3d model with texture
  DrawModelEx(p_data->model, p_data->position, p_data->rotation, p_data->angle, p_data->scale, p_data->color);

  if (draw_wires) {
    DrawModelWiresEx(p_data->model, p_data->position, p_data->rotation, p_data->angle, p_data->scale, BLUE);   // Draw 3d model with texture
  }

  return mrb_nil_value();
}


static mrb_value game_init(mrb_state* mrb, mrb_value self)
{
  // Initialization
  mrb_value game_name = mrb_nil_value();
  mrb_int screenWidth,screenHeight,screenFps;

  mrb_get_args(mrb, "oiii", &game_name, &screenWidth, &screenHeight, &screenFps);

  char *c_game_name = RSTRING_PTR(game_name);

  //SetConfigFlags(FLAG_MSAA_4X_HINT);

  InitWindow(screenWidth, screenHeight, c_game_name);

  play_data_s *p_data;

  p_data = malloc(sizeof(play_data_s));
  memset(p_data, 0, sizeof(play_data_s));
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not allocate @data");
  }

  p_data->buffer_target = LoadRenderTexture(screenWidth, screenHeight);

  mrb_iv_set(
      mrb, self, mrb_intern_lit(mrb, "@pointer"), // set @data
      mrb_obj_value(                           // with value hold in struct
          Data_Wrap_Struct(mrb, mrb->object_class, &play_data_type, p_data)));

#ifndef PLATFORM_WEB

  SetTargetFPS(screenFps);

#endif

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


static mrb_value deltas_model(mrb_state* mrb, mrb_value self)
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

  p_data->scale.x = x;
  p_data->scale.y = y;
  p_data->scale.z = z;

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
  mrb_float ox,oy,oz;

  mrb_get_args(mrb, "ffffff", &yaw, &pitch, &roll, &ox, &oy, &oz);

  model_data_s *p_data = NULL;
  mrb_value data_value; // this IV holds the data

  data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@pointer"));

  Data_Get_Struct(mrb, data_value, &model_data_type, p_data);
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }

  Matrix transform = MatrixIdentity();

  transform = MatrixMultiply(transform, MatrixTranslate(ox, oy, oz));
  transform = MatrixMultiply(transform, MatrixRotateZ(DEG2RAD*roll));
  transform = MatrixMultiply(transform, MatrixRotateX(DEG2RAD*pitch));
  transform = MatrixMultiply(transform, MatrixRotateY(DEG2RAD*yaw));
  transform = MatrixMultiply(transform, MatrixTranslate(-ox, -oy, -oz));

  p_data->model.transform = transform;

  return mrb_nil_value();
}

static mrb_value label_model(mrb_state* mrb, mrb_value self)
{
  mrb_value label_txt = mrb_nil_value();
  mrb_get_args(mrb, "o", &label_txt);

  char *c_label_txt = RSTRING_PTR(label_txt);

  model_data_s *p_data = NULL;
  mrb_value data_value; // this IV holds the data

  data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@pointer"));

  Data_Get_Struct(mrb, data_value, &model_data_type, p_data);
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }

  Vector3 cubePosition = p_data->position;

  Vector2 cubeScreenPosition;
  cubeScreenPosition = GetWorldToScreen((Vector3){cubePosition.x, cubePosition.y + 0.5f, cubePosition.z}, global_p_data->camera);

  DrawText(c_label_txt, cubeScreenPosition.x - MeasureText(c_label_txt, 10) / 2, cubeScreenPosition.y, 3, p_data->label_color);

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


static mrb_value draw_fps(mrb_state* mrb, mrb_value self)
{
  mrb_int a,b;

  mrb_get_args(mrb, "ii", &a, &b);

  DrawFPS(a, b);

  return mrb_nil_value();
}


void UpdateDrawFrame(void) {
  mrb_value gtdt = mrb_ary_new(global_mrb);

  double time;
  float dt;

  time = GetTime();
  dt = GetFrameTime();

  mrb_ary_set(global_mrb, gtdt, 0, mrb_float_value(global_mrb, time));
  mrb_ary_set(global_mrb, gtdt, 1, mrb_float_value(global_mrb, dt));

  global_p_data->mousePosition = GetMousePosition();

  //SetCameraMode(global_p_data->camera, CAMERA_FIRST_PERSON);
  //SetCameraMode(global_p_data->camera, CAMERA_FREE);
  UpdateCamera(&global_p_data->camera);

  BeginDrawing();

  ClearBackground(BLACK);

  mrb_yield_argv(global_mrb, global_block, 2, &gtdt);

  EndDrawing();

  mrb_yield_argv(global_mrb, global_block, 0, NULL);
}


static mrb_value main_loop(mrb_state* mrb, mrb_value self)
{
  //TODO: fix this hack???
  global_mrb = mrb;

  mrb_get_args(mrb, "&", &global_block);

  //play_data_s *p_data = NULL;
  //mrb_value data_value;     // this IV holds the data
  global_data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@pointer"));

  Data_Get_Struct(mrb, global_data_value, &play_data_type, global_p_data);
  if (!global_p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }

  SetCameraMode(global_p_data->camera, CAMERA_FIRST_PERSON);

#ifdef PLATFORM_WEB
  emscripten_set_main_loop(UpdateDrawFrame, 0, 1);
#else
  // Main game loop
  while (!WindowShouldClose()) // Detect window close button or ESC key
  {
    UpdateDrawFrame();
  }
#endif

  CloseWindow(); // Close window and OpenGL context

  return mrb_nil_value();
}




static mrb_value lookat(mrb_state* mrb, mrb_value self)
{
  mrb_int type;
  mrb_float px,py,pz,tx,ty,tz,fovy;

  mrb_get_args(mrb, "ifffffff", &type, &px, &py, &pz, &tx, &ty, &tz, &fovy);

  play_data_s *p_data = NULL;
  mrb_value data_value;     // this IV holds the data
  data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@pointer"));

  Data_Get_Struct(mrb, data_value, &play_data_type, p_data);
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }

  // Camera mode type
  switch(type) {
    case 0:
      p_data->camera.type = CAMERA_ORTHOGRAPHIC;
      //SetCameraMode(p_data->camera, CAMERA_ORBITAL);
      //SetCameraMode(p_data->camera, CAMERA_THIRD_PERSON);
      break;
    case 1:
      p_data->camera.type = CAMERA_PERSPECTIVE;
      //SetCameraMode(p_data->camera, CAMERA_FIRST_PERSON);
      //SetCameraMode(p_data->camera, CAMERA_ORBITAL);
      break;
  }

  // Define the camera to look into our 3d world
  p_data->camera.position = (Vector3){ px, py, pz };    // Camera position
  p_data->camera.target = (Vector3){ tx, ty, tz };      // Camera looking at point

  p_data->camera.up = (Vector3){ 0.0f, 1.0f, 0.0f };          // Camera up vector (rotation towards target)
  p_data->camera.fovy = fovy;                                 // Camera field-of-view Y

  return mrb_nil_value();
}


static mrb_value threed(mrb_state* mrb, mrb_value self)
{
  mrb_value block;
  mrb_get_args(mrb, "&", &block);

  play_data_s *p_data = NULL;
  mrb_value data_value;     // this IV holds the data
  data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@pointer"));

  Data_Get_Struct(mrb, data_value, &play_data_type, p_data);
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }

  BeginMode3D(p_data->camera);

  mrb_yield_argv(mrb, block, 0, NULL);

  EndMode3D();

  return mrb_nil_value();
}


static mrb_value twod(mrb_state* mrb, mrb_value self)
{
  mrb_value block;
  mrb_get_args(mrb, "&", &block);

  play_data_s *p_data = NULL;
  mrb_value data_value;     // this IV holds the data
  data_value = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@pointer"));

  Data_Get_Struct(mrb, data_value, &play_data_type, p_data);
  if (!p_data) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "Could not access @pointer");
  }

  //BeginMode2D(p_data->camera);

  mrb_yield_argv(mrb, block, 0, NULL);

  //EndMode2D();

  return mrb_nil_value();
}


int main(int argc, char** argv) {
  mrb_state *mrb;
  struct mrb_parser_state *ret;

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
  mrb_define_method(mrb, game_class, "lookat", lookat, MRB_ARGS_REQ(8));
  mrb_define_method(mrb, game_class, "draw_grid", draw_grid, MRB_ARGS_REQ(2));
  mrb_define_method(mrb, game_class, "draw_fps", draw_fps, MRB_ARGS_REQ(2));
  mrb_define_method(mrb, game_class, "mousep", mousep, MRB_ARGS_BLOCK());
  mrb_define_method(mrb, game_class, "keyspressed", keyspressed, MRB_ARGS_ANY());
  mrb_define_method(mrb, game_class, "main_loop", main_loop, MRB_ARGS_BLOCK());
  mrb_define_method(mrb, game_class, "threed", threed, MRB_ARGS_BLOCK());
  mrb_define_method(mrb, game_class, "twod", twod, MRB_ARGS_BLOCK());

  struct RClass *model_class = mrb_define_class(mrb, "Model", mrb->object_class);
  mrb_define_method(mrb, model_class, "initialize", model_init, MRB_ARGS_REQ(3));
  mrb_define_method(mrb, model_class, "draw", draw_model, MRB_ARGS_NONE());
  mrb_define_method(mrb, model_class, "deltap", deltap_model, MRB_ARGS_REQ(3));
  mrb_define_method(mrb, model_class, "deltar", deltar_model, MRB_ARGS_REQ(4));
  mrb_define_method(mrb, model_class, "deltas", deltas_model, MRB_ARGS_REQ(3));
  mrb_define_method(mrb, model_class, "yawpitchroll", yawpitchroll_model, MRB_ARGS_REQ(6));
  mrb_define_method(mrb, model_class, "label", label_model, MRB_ARGS_REQ(1));

  struct RClass *cube_class = mrb_define_class(mrb, "Cube", model_class);
  mrb_define_method(mrb, cube_class, "initialize", cube_init, MRB_ARGS_REQ(4));

  struct RClass *sphere_class = mrb_define_class(mrb, "Sphere", model_class);
  mrb_define_method(mrb, sphere_class, "initialize", sphere_init, MRB_ARGS_REQ(4));

  eval_static_libs(mrb, shmup, snake, box, kube, init, NULL);

/*
  FILE *fd = fopen("/dev/stdin", "r"); //fcntl(STDIN_FILENO,  F_DUPFD, 0);
  mrbc_context *detective_file = mrbc_context_new(mrb);
  mrbc_filename(mrb, detective_file, "STDIN");
  ret = mrb_parse_file(mrb, fd, detective_file);
  mrbc_context_free(mrb, detective_file);
  fclose(fd);
  if_exception_error_and_exit(mrb, "Exception in STDIN\n");
*/

  mrb_close(mrb);

  fprintf(stderr, "exiting ... \n");

  return 0;
}
