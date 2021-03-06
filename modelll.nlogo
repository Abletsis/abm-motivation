breed [ organisations organisation ]
breed [ groups group ]
breed [ individuals individual ]

globals [
  market-trend
  past-trend
  total-market-size
  effective-market-size
 ;brands
  brand-choice
  non-sustainable
  marginally-sustainable
  moderately-sustainable
  quite-sustainable
  sustainable
  ;competition
  prosociality-group
  prosociality-organisation
  weight-instrumental
  weight-normative
  ;policies: sustainability-subsidy, legacy-tax and support-sustainable-behaviour
]


organisations-own [
  infrastructure
  brand ;  [ non-sustainable marginally-sustainable moderately-sustainable quite-sustainable sustainable ]
  clock ; +1 every tick [ update clock ( clock clock + 1 )  init with random 100 + 1 ] 2 54 35 86 1 -> 3 55 35 87 2
  factor
  instrumental-motivation
  normative-motivation
  org-size
  investment-decision
  past-decisions
  ]

groups-own [
  organisation-id
  level-id
  power
  instrumental-motivation
  normative-motivation
  average-instrumental-motivation ; list\
  lower-lvl-normative
]

individuals-own [
  group-id
  organisation-id
  power
  instrumental-motivation
  normative-motivation
]

to setup
  clear-all
  reset-ticks
  setup-globals
  setup-organisations
end

to setup-globals
  set non-sustainable 0
  set past-trend n-values organisation-memory [initial-market-trend]
  set marginally-sustainable 0.25
  set moderately-sustainable 0.5
  set quite-sustainable 0.75
  set sustainable 1
  set weight-instrumental 0.7
  set weight-normative 0.3
  set brand-choice (list non-sustainable marginally-sustainable moderately-sustainable quite-sustainable sustainable)
  ifelse external-competition = "low" [ set prosociality-organisation 0.8 set prosociality-group 1.2 ]
  [ ifelse external-competition = "medium" [ set prosociality-organisation 1 set prosociality-group 1 ]
    [ set prosociality-organisation 1.2 set prosociality-group 0.8 ] ]
end

to setup-organisations
  create-organisations number-organisations
  ask organisations [
    set clock random 100
    set brand one-of brand-choice
    set infrastructure brand
    set normative-motivation infrastructure * 100
    set instrumental-motivation ceiling ( ( ( ( market-trend + infrastructure ) / 2 ) * sustainability-subsidy + ( 1 - infrastructure )  * legacy-tax ) * prosociality-organisation * 100 )
    let variance-list ( list ( random ( variance-groups ) * 1.01 ) ( random (variance-groups * -1.01) ) )
    hatch-groups ( average-group + one-of variance-list ) [
      set organisation-id [ who ] of myself
      let zero 0
      let variance-nm []
      ifelse [ brand ] of myself = 0 [ set variance-nm ( list ( zero ) ( random ( variance-normative-motivation ) * 1.01 ) ) ][ set variance-nm ( list ( random ( variance-normative-motivation ) * 1.01 ) ( random ( variance-normative-motivation * -1.01 ) ) ) ]
      set power 1
      set normative-motivation ( [normative-motivation] of myself + one-of variance-nm )
      set instrumental-motivation  ceiling ( ( [ instrumental-motivation ] of myself ) * ( normative-motivation / 100 ) )
      set average-instrumental-motivation map [ instrumental-motivation ] [ 1 1 1 1 1 ]
      hatch-individuals 25 [
        set group-id [ who ] of myself
        set power 1
        set organisation-id [ organisation-id ] of myself
        set normative-motivation ( [ normative-motivation ] of myself + one-of  variance-nm )
        set instrumental-motivation ceiling ( ( [ instrumental-motivation ] of myself ) * (normative-motivation / 100 ) )
      ]
    ]
    set org-size ( count groups with [ organisation-id = [ who ] of myself ] ) * 25
    set total-market-size total-market-size + org-size
  ]
end

to setup-initial-market-trend
  ask organisations [
    set investment-decision one-of [ 1 0 ]
    set effective-market-size ( effective-market-size +  investment-decision * org-size )
    set total-market-size ( total-market-size + org-size )
  ]
  set market-trend effective-market-size / total-market-size
end


to update-istrumental-motivation-organisations
  ask organisations [
    set instrumental-motivation ceiling ( ( ( ( ( ( reduce + past-trend )  / organisation-memory  )  + infrastructure ) / 2 ) * sustainability-subsidy + ( 1 - infrastructure )  * legacy-tax ) * prosociality-organisation * normative-motivation )
    ifelse instrumental-motivation < 1 [ set instrumental-motivation 1 ] [ if instrumental-motivation > 100 [ set instrumental-motivation 100 ] ]
  ]
end

to update-instrumental-motivation-groups
  ask groups [
    set instrumental-motivation  ceiling ( ( [ instrumental-motivation ] of organisation organisation-id ) * normative-motivation / 100 )
    ifelse instrumental-motivation < 1 [ set instrumental-motivation 1 ] [ if instrumental-motivation > 100 [ set instrumental-motivation 100 ] ]
    set average-instrumental-motivation remove-item 4 average-instrumental-motivation
    set average-instrumental-motivation insert-item 0 average-instrumental-motivation instrumental-motivation
  ]
end

to update-instrumental-motivation-individuals
  ask individuals [
    set instrumental-motivation ceiling ( ( [ instrumental-motivation ] of group group-id ) * normative-motivation / 100 )
    ifelse instrumental-motivation < 1 [ set instrumental-motivation 1 ] [ if instrumental-motivation > 100 [ set instrumental-motivation 100 ] ]
  ]
end

to update-normative-motivation-individuals
  ask individuals [
    let av-instrumental-motivation 0
    ask group group-id [
      set av-instrumental-motivation reduce + average-instrumental-motivation / 5
    ]
    set normative-motivation ( normative-motivation * ( 1 + ( ( av-instrumental-motivation - normative-motivation ) / av-instrumental-motivation ) ) * support-sustainable-behaviour )
    ifelse normative-motivation < 1 [ set normative-motivation 1 ] [ if normative-motivation > 100 [ set normative-motivation 100 ] ]
  ]
end

to update-normative-motivation-groups
  ask groups [
    let summation-normative-motivations 0
    ask individuals with [ group-id = [ who ] of myself ] [
      set summation-normative-motivations summation-normative-motivations + power * normative-motivation
    ]
    set normative-motivation ( summation-normative-motivations / 25 ) * prosociality-group
    ifelse normative-motivation < 1 [ set normative-motivation 1 ] [ if normative-motivation > 100 [ set normative-motivation 100 ] ]
  ]
end

to make-investment-decision
  set effective-market-size 0
  ask organisations [
    set investment-decision 0
    if ( clock mod 20 = 0 ) [
    ifelse brand >= 0.5 [ set factor ( 2 - prosociality-organisation ) ]
    [ set factor ( 4 - ( prosociality-organisation + support-sustainable-behaviour ) ) / 2 ]
    ifelse ( weight-instrumental * instrumental-motivation + weight-normative * normative-motivation ) >= factor * investment-threshold [
      set effective-market-size effective-market-size + org-size
      set investment-decision 1
      if infrastructure != 1 [
        ifelse instrumental-motivation >= 100 [ set instrumental-motivation 100 ] [ set instrumental-motivation instrumental-motivation + improvement ]
        set infrastructure infrastructure + 0.05
      ]
    ][
      set investment-decision 0
      if instrumental-motivation >= demotivate [ set instrumental-motivation instrumental-motivation - demotivate ]
    ]
  ]
  ]
end

to update-market-trend
  ifelse ( count organisations with [ clock mod 20 = 0 ] ) != 0 and ( count organisations with [ investment-decision = 1 ] ) != 0 [
    set market-trend ( ( reduce + [ org-size ] of organisations with [ investment-decision = 1 ] )  / ( reduce + [ org-size ] of organisations with [ clock mod 20 = 0 ] ) )
    set past-trend butlast past-trend
    set past-trend fput market-trend past-trend
  ][
    set market-trend one-of past-trend
    ;set past-trend butlast past-trend
    ;set past-trend fput ( 0.8 * market-trend ) past-trend
  ]
end

to update-brand
  ask organisations [ if infrastructure > ( brand + 0.1 ) and brand != 1  [ set brand brand + 0.25 ] ]
end

to update-normative-motivation-organisations
  ask organisations [
    let summation-normative-motivations 0
    ask groups with [ organisation-id = [ who ] of myself and level-id = 1 ] [
      set summation-normative-motivations summation-normative-motivations + power * normative-motivation
    ]
    set normative-motivation ( summation-normative-motivations / ( org-size / 25 ) ) * support-sustainable-behaviour * prosociality-group
   ifelse normative-motivation < 1 [ set normative-motivation 1 ] [ if normative-motivation > 100 [ set normative-motivation 100 ] ]
  ]
end

to update-clock
  ask organisations [ set clock clock + 1 ]
end

to go
  update-istrumental-motivation-organisations
  update-instrumental-motivation-groups
  update-instrumental-motivation-individuals
  update-normative-motivation-individuals
  update-normative-motivation-groups
  make-investment-decision
  update-brand
  update-normative-motivation-organisations
  update-market-trend
  update-clock
  ifelse ticks < 200 [ tick ] [ stop ]
end

; each group has a level id and the organisation that they are part of have a total level number.
; we have agreed that each group at the same level an equal amount of power however power is distributed over the different levels
; less powerful organisations are positioned in the lower levels of the organisation
; knowing that a group has a level id, organisation id we are supposed to perform the calculation
; another note !!! -- THERE IS NO CHECK WHETHER OR NOT THE NORMATIVE-MOTIVATION WILL EXCEED 100
;;; ----- expensive version ------ ;;;
to update-normative-motivation-groups-2
  ask organisations [ ; think about whether or not we would like to add prosociality in there then multiply prosociality as the norm is passed onto the other level
    let i levels ; the amount of levels the organisation has in its structure
    while i > 1 [
      let n-motivation-of-lvl 0
      let a 0
      let b 0
      set b [normative-motivation ] of groups with [ organisation-id = [ who ] of myself and level-id = i ]
      set a length b
      set n-motivation-of-lvl int ( reduce + b ) / a
      let id 0
      let powers 0
      ask one-of groups with [ organisation-id = [ who ] of myself  and level-id = 1 ] [ set id who ]
      set powers [ power ] of group id
      ask groups with [ organisation-id of myself organisation-id = [ who ] of myself and level-id = ( i - 1 ) ] [
        set normative-motivation  ( ( 2 - powers ) * normative-motivation + powers * n-motivation-of-lvl ) / 2
      ]
    set i i - 1
    ]
  ]
end


;; same for normative..
to update-instrumental-motivation-groups-2
  ask organisations [
    let inst-mot instrumental-motivation
    ask groups with [ organisation-id = [ who ] of myself and level-id = 1 ] [
      set instrumental-motivation ceiling ( ( instr-mot ) * normative-motivation / 100 )
    let i 2
    while i <= levels [
        ask groups with [ organisation-id = [ who ] of myself and level-id = i ] [
          set instrumental-motivation  ceiling ( ( one-of [ instrumental-motivation ] of groups with [ organisation-id = organisation-id of myself and level-id ( i - 1 ) ] ) * normative-motivation / 100 )
          ifelse instrumental-motivation < 1 [ set instrumental-motivation 1 ] [ if instrumental-motivation > 100 [ set instrumental-motivation 100 ] ]
          set average-instrumental-motivation remove-item 4 average-instrumental-motivation
          set average-instrumental-motivation insert-item 0 average-instrumental-motivation instrumental-motivation
        ]
        set i i + 1
      ]
end

;;the normative motivation update for organisations requires to be updated.Why? becasue it should only accept the normative motivation of the groups with level id 1
to update-normative-motivation-organisations-2
  ask organisations [
    let summation-normative-motivations 0
    let counter 0
    ask groups with [ organisation-id = [ who ] of myself and level-id = 1 ] [
      set summation-normative-motivations summation-normative-motivations + normative-motivation
      set counter counter + 1
    ]
    set normative-motivation ( summation-normative-motivations / counter ) * support-sustainable-behaviour * prosociality-group ;; !! NOTE !! we could do something with the investment decision here
   ifelse normative-motivation < 1 [ set normative-motivation 1 ] [ if normative-motivation > 100 [ set normative-motivation 100 ] ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
1798
568
1890
661
-1
-1
2.55
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
20
19
86
52
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
25
82
181
127
external-competition
external-competition
"high" "medium" "low"
2

SLIDER
24
203
57
365
sustainability-subsidy
sustainability-subsidy
1
2
0.0
0.1
1
NIL
VERTICAL

SLIDER
68
204
101
354
legacy-tax
legacy-tax
0
1
0.0
0.1
1
NIL
VERTICAL

SLIDER
111
203
144
420
support-sustainable-behaviour
support-sustainable-behaviour
1
2
0.0
0.1
1
NIL
VERTICAL

SLIDER
24
165
201
198
initial-market-trend
initial-market-trend
0
1
0.0
0.5
1
NIL
HORIZONTAL

SLIDER
24
130
217
163
number-organisations
number-organisations
3
20
0.0
1
1
NIL
HORIZONTAL

BUTTON
90
19
153
52
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
159
19
222
52
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
221
130
393
163
average-group
average-group
1
40
0.0
1
1
NIL
HORIZONTAL

SLIDER
398
129
570
162
variance-groups
variance-groups
0
average-group - 1
20.0
1
1
NIL
HORIZONTAL

SLIDER
222
174
410
207
investment-threshold
investment-threshold
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
398
93
570
126
improvement
improvement
0
10
0.0
1
1
NIL
HORIZONTAL

PLOT
1261
55
1461
205
market-trend
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot market-trend"

PLOT
664
54
1049
235
average-motivation
ticks
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"instr-mot" 1.0 0 -16777216 true "" "plot ( reduce + [ instrumental-motivation ] of organisations ) / number-organisations"
"norm-mot" 1.0 0 -7500403 true "" "plot ( reduce + [ normative-motivation ] of organisations ) / number-organisations"

PLOT
1053
55
1253
205
Brand
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot ( sum [ brand ] of organisations ) / number-organisations"

MONITOR
1465
55
1527
100
brand 1
count organisations with [ brand = 1 ]
17
1
11

MONITOR
1465
107
1546
152
brand 0.75
count organisations with [ brand = 0.75 ]
17
1
11

MONITOR
1466
158
1539
203
brand 0.5
count organisations with [ brand = 0.5 ]
17
1
11

MONITOR
1466
207
1547
252
brand 0.25
count organisations with [ brand = 0.25 ]
17
1
11

MONITOR
1466
257
1528
302
brand 0
count organisations with [ brand = 0 ]
17
1
11

SLIDER
221
213
442
246
organisation-memory
organisation-memory
0
40
0.0
1
1
ticks
HORIZONTAL

PLOT
1054
210
1254
360
longterm market trend
ticks
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot ( reduce + past-trend ) / organisation-memory"

SLIDER
221
92
393
125
demotivate
demotivate
0
10
0.0
1
1
NIL
HORIZONTAL

PLOT
1259
210
1459
360
investment decisions
ticks
NIL
0.0
10.0
0.0
3.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot reduce + [ investment-decision ] of organisations"

SLIDER
221
251
440
284
variance-normative-motivation
variance-normative-motivation
0
20
0.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
