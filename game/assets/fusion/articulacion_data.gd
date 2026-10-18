extends RefCounted
const DATA = {
  "Pelvis": {
    "parent": "",
    "pivot": [
      0.0,
      0.435,
      0.0
    ],
    "shared_vertices": 0
  },
  "Torso_Abdomen": {
    "parent": "Pelvis",
    "pivot": [
      0.001867,
      0.519456,
      -0.049384
    ],
    "shared_vertices": 79
  },
  "Torso_Pecho": {
    "parent": "Torso_Abdomen",
    "pivot": [
      -0.00502,
      0.601871,
      -0.066869
    ],
    "shared_vertices": 57
  },
  "Cabeza": {
    "parent": "Torso_Pecho",
    "pivot": [
      -0.015755,
      0.713997,
      -0.013997
    ],
    "shared_vertices": 30
  },
  "Antena_Der": {
    "parent": "Cabeza",
    "pivot": [
      -0.040771,
      0.765137,
      -0.038329
    ],
    "shared_vertices": 8
  },
  "Antena_Izq": {
    "parent": "Cabeza",
    "pivot": [
      0.037597,
      0.765138,
      -0.046386
    ],
    "shared_vertices": 8
  },
  "Hombro_Der": {
    "parent": "Torso_Pecho",
    "pivot": [
      -0.119059,
      0.672688,
      -0.010661
    ],
    "shared_vertices": 24
  },
  "BrazoSuperior_Der": {
    "parent": "Hombro_Der",
    "pivot": [
      -0.201115,
      0.668772,
      -0.001435
    ],
    "shared_vertices": 17
  },
  "Antebrazo_Der": {
    "parent": "BrazoSuperior_Der",
    "pivot": [
      -0.302952,
      0.658093,
      0.000217
    ],
    "shared_vertices": 18
  },
  "Mano_Der": {
    "parent": "Antebrazo_Der",
    "pivot": [
      -0.436089,
      0.659072,
      0.023871
    ],
    "shared_vertices": 18
  },
  "Muslo_Der": {
    "parent": "Pelvis",
    "pivot": [
      -0.066376,
      0.422881,
      -0.01672
    ],
    "shared_vertices": 33
  },
  "Rodilla_Der": {
    "parent": "Muslo_Der",
    "pivot": [
      -0.094657,
      0.31836,
      0.008649
    ],
    "shared_vertices": 28
  },
  "Pantorrilla_Der": {
    "parent": "Rodilla_Der",
    "pivot": [
      -0.095407,
      0.26244,
      -0.016518
    ],
    "shared_vertices": 46
  },
  "Pie_Der": {
    "parent": "Pantorrilla_Der",
    "pivot": [
      -0.110142,
      0.100934,
      0.017927
    ],
    "shared_vertices": 28
  },
  "Hombro_Izq": {
    "parent": "Torso_Pecho",
    "pivot": [
      0.116737,
      0.668494,
      -0.051758
    ],
    "shared_vertices": 26
  },
  "BrazoSuperior_Izq": {
    "parent": "Hombro_Izq",
    "pivot": [
      0.201388,
      0.674372,
      -0.040907
    ],
    "shared_vertices": 18
  },
  "Antebrazo_Izq": {
    "parent": "BrazoSuperior_Izq",
    "pivot": [
      0.300293,
      0.663965,
      -0.072364
    ],
    "shared_vertices": 20
  },
  "Mano_Izq": {
    "parent": "Antebrazo_Izq",
    "pivot": [
      0.434341,
      0.660502,
      -0.066234
    ],
    "shared_vertices": 17
  },
  "Muslo_Izq": {
    "parent": "Pelvis",
    "pivot": [
      0.066894,
      0.425049,
      -0.028662
    ],
    "shared_vertices": 40
  },
  "Rodilla_Izq": {
    "parent": "Muslo_Izq",
    "pivot": [
      0.0951,
      0.318452,
      -0.027669
    ],
    "shared_vertices": 21
  },
  "Pantorrilla_Izq": {
    "parent": "Rodilla_Izq",
    "pivot": [
      0.091715,
      0.259262,
      -0.031055
    ],
    "shared_vertices": 35
  },
  "Pie_Izq": {
    "parent": "Pantorrilla_Izq",
    "pivot": [
      0.117773,
      0.098438,
      -0.002148
    ],
    "shared_vertices": 35
  }
}
