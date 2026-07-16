cmake_minimum_required(VERSION 3.20)

project(peonpad_theora_encoder C)

foreach(required PEONPAD_ROOT OGG_LIBRARY VORBIS_LIBRARY VORBISENC_LIBRARY)
  if(NOT DEFINED ${required})
    message(FATAL_ERROR "Set ${required} when configuring the Theora fallback")
  endif()
endforeach()

set(THEORA_ROOT "${PEONPAD_ROOT}/engine/stratagus/third-party/theora")
set(OGG_INCLUDE
  "${PEONPAD_ROOT}/engine/stratagus/third-party/SDL_mixer/external/ogg/include")
set(VORBIS_INCLUDE
  "${PEONPAD_ROOT}/engine/stratagus/third-party/SDL_mixer/external/vorbis/include")

add_library(peonpad_theoraenc STATIC
  "${THEORA_ROOT}/lib/apiwrapper.c"
  "${THEORA_ROOT}/lib/fragment.c"
  "${THEORA_ROOT}/lib/idct.c"
  "${THEORA_ROOT}/lib/internal.c"
  "${THEORA_ROOT}/lib/info.c"
  "${THEORA_ROOT}/lib/state.c"
  "${THEORA_ROOT}/lib/quant.c"
  "${THEORA_ROOT}/lib/analyze.c"
  "${THEORA_ROOT}/lib/fdct.c"
  "${THEORA_ROOT}/lib/encfrag.c"
  "${THEORA_ROOT}/lib/encapiwrapper.c"
  "${THEORA_ROOT}/lib/encinfo.c"
  "${THEORA_ROOT}/lib/encode.c"
  "${THEORA_ROOT}/lib/enquant.c"
  "${THEORA_ROOT}/lib/huffenc.c"
  "${THEORA_ROOT}/lib/mathops.c"
  "${THEORA_ROOT}/lib/mcenc.c"
  "${THEORA_ROOT}/lib/rate.c"
  "${THEORA_ROOT}/lib/tokenize.c"
)
target_include_directories(peonpad_theoraenc PRIVATE
  "${THEORA_ROOT}/lib"
  "${THEORA_ROOT}/include"
  "${OGG_INCLUDE}"
)
target_compile_options(peonpad_theoraenc PRIVATE
  -Wno-parentheses
  -Wno-shift-negative-value
  -Wno-shift-op-parentheses
)

add_executable(encoder_example
  "${THEORA_ROOT}/examples/encoder_example.c"
  "${THEORA_ROOT}/examples/getopt.c"
  "${THEORA_ROOT}/examples/getopt1.c"
)
target_include_directories(encoder_example PRIVATE
  "${THEORA_ROOT}/include"
  "${OGG_INCLUDE}"
  "${VORBIS_INCLUDE}"
)
target_compile_options(encoder_example PRIVATE
  -Wno-deprecated-non-prototype
  -Wno-shift-op-parentheses
)
target_link_libraries(encoder_example PRIVATE
  peonpad_theoraenc
  "${VORBISENC_LIBRARY}"
  "${VORBIS_LIBRARY}"
  "${OGG_LIBRARY}"
)
