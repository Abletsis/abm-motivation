;; PEP-350 for codetags
;; PEP-8 for naming conventions

extensions [palette]

;; -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;; Breeds
;; -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
breed [organisations organisation]
breed [groups group]
breed [individuals individual]
breed [halos halo]


;; -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;; 0. Globals
;; -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
globals [
  ;; Global constants
  IMPROVEMENT
  DEMOTIVATION
  WEIGHT-INSTRUMENTAL
  WEIGHT-NORMATIVE
  N-INDIVIDUALS-PER-GROUP
  BRANDS

  ;; Global variables
  market-trend
  past-trend

  n-hierarchical
  n-intermediate
  n-flat

  sixteen-personalities

  total-market-size
  effective-market-size

  ;;
  TIME

  ;; outcomes
  n-brand-0
  n-brand-1
  n-brand-2
  n-brand-3
  n-brand-4
]

;; -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;; 1. Organisations attributes
;; -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
organisations-own [
  n-groups
  n-individuals
  organisation-instrumental-motivation
  organisation-normative-motivation
  organisation-prosociality
  organisational-structure
  n-levels
  brand
  infrastructure
  clock ;; internal clock for organisations
  factor
  investment-decision
  past-decisions
  org-size
  organisation-weight-inst
  organisation-weight-norm
  my-groups
  my-halos
]

;; -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;; 2. Groups attributes
;; -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
groups-own [
  organisation-id
  group-prosociality
  group-power
  group-instrumental-motivation
  group-normative-motivation
  group-level-id
  group-average-instrumental-motivation
  group-weight-inst
  group-weight-norm
  my-individuals
]

;; -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;; 3. Individuals attributes
;; -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
individuals-own [
  personality
  group-id
  organisation-id
  individual-power
  weight-inst
  weight-norm
  individual-instrumental-motivation
  individual-normative-motivation
]

;; -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;; 4. Halos attributes
;; -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
halos-own [
  organisation-id
  core-id
]



;; -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;; SETUP & GO
;; ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
to setup
  clear-all
  reset-ticks
  setup-globals
  setup-number-of-organisations
  setup-market-trend
  setup-organisations
  setup-personalities
  setup-weights-groups-and-organisations

  if visual? = true [
    setup-visualization
  ]

  set TIME ticks
  set n-brand-0 count organisations with [ brand = 0 ]
  set n-brand-1 count organisations with [ brand = 0.25 ]
  set n-brand-2 count organisations with [ brand = 0.5 ]
  set n-brand-3 count organisations with [ brand = 0.75 ]
  set n-brand-4 count organisations with [ brand = 1 ]
end

to go
  update-instrumental-motivation-organisations
  if visual? = true [
    update-instrumental-motivation-organisations-visualization
  ]
  update-instrumental-motivation-groups
  if visual? = true [
    update-instrumental-motivation-groups-visualization
  ]
  update-instrumental-motivation-individuals
  if visual? = true [
    update-instrumental-motivation-individuals-visualization
  ]
  update-normative-motivation-individuals
  if visual? = true [
    update-normative-motivation-individuals-visualization
  ]
  update-normative-motivation-groups
  if visual? = true [
    update-normative-motivation-groups-visualization
  ]
  make-investment-decision
  update-brand
  update-normative-motivation-organisations
  if visual? = true [
    update-normative-motivation-organisations-visualization
  ]
  update-market-trend
  update-clock

  set n-brand-0 count organisations with [ brand = 0 ]
  set n-brand-1 count organisations with [ brand = 0.25 ]
  set n-brand-2 count organisations with [ brand = 0.5 ]
  set n-brand-3 count organisations with [ brand = 0.75 ]
  set n-brand-4 count organisations with [ brand = 1 ]
  set TIME ticks

  ifelse ticks < 200 [ tick ] [ stop ]

end



;; -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;; 1. Organisations procedures
;; -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
to setup-number-of-organisations

  set-default-shape halos "thin ring"
  set-default-shape organisations "pentagon"
  set-default-shape groups "square"
  set-default-shape individuals "circle"

  create-organisations n-organisations

end

to setup-organisations
  ask organisations [
    set clock random 100
    set brand item 1 one-of brands
    set infrastructure brand
    setup-organisational-prosociality
    select-organisational-structure

    let min-org-mot 0
    let max-org-mot 100

    set organisation-normative-motivation infrastructure * 100
    if organisation-normative-motivation - 25 > 0
    [
      set min-org-mot organisation-normative-motivation - 25
    ]
    if organisation-normative-motivation + 25 < 100
    [
      set max-org-mot organisation-normative-motivation + 25
    ]
    set organisation-normative-motivation random (max-org-mot - min-org-mot) + min-org-mot
    set organisation-instrumental-motivation round ((((market-trend + infrastructure) / 2) * subsidy + (1 - infrastructure) * tax) * organisation-prosociality * (( organisation-normative-motivation + 100 ) / 2 ))

    set organisation-normative-motivation verify-boundaries organisation-normative-motivation
    set organisation-instrumental-motivation verify-boundaries organisation-instrumental-motivation

    ;; Create groups
    hatch-groups n-groups [

      setup-group-prosociality
      set organisation-id [who] of myself
      set group-level-id 0

      let zero 0
      let var []
      ifelse [brand] of myself = 0
      [
        set var (list(zero) (random (variance-normative-motivation) * 1.01 ))
      ]
      [
         ifelse [brand] of myself = 1 [
          let variance-normative random ( variance-normative-motivation * 1.01 )
          set var list ( variance-normative * -1 ) ( zero )
        ]
        [
          let variance-normative random (variance-normative-motivation * 1.01 )
          set var ( list (variance-normative) ( zero ) ((variance-normative * -1) ) )
        ]
      ]

      set group-normative-motivation ([organisation-normative-motivation] of myself + one-of var)
      set group-normative-motivation verify-boundaries group-normative-motivation
      set group-instrumental-motivation round ((([organisation-instrumental-motivation] of myself) + (group-normative-motivation)) / 2 )
      set group-instrumental-motivation verify-boundaries group-instrumental-motivation
      set group-average-instrumental-motivation map [ group-instrumental-motivation ] n-values internalisation-time [ 1 ]

      ;; Create individuals
      hatch-individuals N-INDIVIDUALS-PER-GROUP [

        set organisation-id [organisation-id] of myself
        set group-id [who] of myself
        set personality "NONE"
        set individual-normative-motivation ([group-normative-motivation] of myself + one-of var) ;; ???: Is it correct?
        set individual-normative-motivation verify-boundaries individual-normative-motivation
        set individual-instrumental-motivation round ((([group-instrumental-motivation] of myself) + (individual-normative-motivation)) / 2 )
        set individual-instrumental-motivation verify-boundaries individual-instrumental-motivation
      ]

      set my-individuals individuals with [ (group-id = [who] of myself) and (organisation-id = [organisation-id] of myself)]

    ]

    set my-groups groups with [(organisation-id = [who] of myself)]

    assign-groups-to-level ; This functions assigns groups to different levels within an organisation
    allocate-power-groups
    allocate-power-individuals


  ]
end

to update-instrumental-motivation-organisations
  ask organisations
  [
    set organisation-instrumental-motivation round ( ( ( ( ( ( reduce + past-trend ) / organisation-memory ) + infrastructure ) / 2 ) * subsidy
      + ( 1 - infrastructure ) * tax ) * organisation-prosociality * (organisation-weight-inst * organisation-instrumental-motivation + organisation-weight-norm * organisation-normative-motivation ) )
    set organisation-instrumental-motivation verify-boundaries organisation-instrumental-motivation

  ]
end

to update-normative-motivation-organisations
  ask organisations
  [
    let average-group-normative-motivation mean [ group-normative-motivation ] of my-groups with [ group-level-id = 1 ]
    let powers one-of [ group-power ] of my-groups with [ group-level-id = 1 ]
    set organisation-normative-motivation ( ( ( 2 - powers ) * organisation-normative-motivation * support-for-sustainable-behaviour + powers * ( average-group-normative-motivation ) * ( 2 - organisation-prosociality ) ) / 2 )
    set organisation-normative-motivation verify-boundaries organisation-normative-motivation
  ]
end

to update-brand
  ask organisations
  [
    if infrastructure > ( brand + 0.1 ) and brand != 1
    [
      set brand brand + 0.25
    ]
  ]
end

to update-clock
  ask organisations [
    set clock clock + 1
  ]
end

to make-investment-decision
  ask organisations [
    set investment-decision 0
    if ( clock mod 20 = 0) [
      ifelse brand >= 0.5
      [
        set factor ( 1.9 - organisation-prosociality )
        set factor ( verify-boundaries ( factor * 100 ) ) / 100
      ]
      [
        set factor (3.4 - ( organisation-prosociality + support-for-sustainable-behaviour ) ) / 2
        set factor ( verify-boundaries ( factor * 100 ) ) / 100
      ]
      ifelse ( organisation-weight-inst * organisation-instrumental-motivation + organisation-weight-norm * organisation-normative-motivation ) >= factor * threshold
      [
        set investment-decision 1
        if infrastructure != 1 [
          ifelse organisation-instrumental-motivation >= 100
          [
            set organisation-instrumental-motivation 100
          ]
          [
            set organisation-instrumental-motivation organisation-instrumental-motivation + ( organisation-instrumental-motivation * ( random IMPROVEMENT + 1 ) / 100 )
          ]
          set infrastructure infrastructure + 0.05
        ]
      ]
      [
        set investment-decision 0
        set organisation-instrumental-motivation organisation-instrumental-motivation - ( organisation-instrumental-motivation * ( random DEMOTIVATION + 1 ) / 100 )
      ]
    ]
  ]
end

to setup-organisational-prosociality
    ifelse external-competition = "low" [ set organisation-prosociality 0.8 ]
    [ ifelse external-competition = "medium" [ set organisation-prosociality 1 ]
      [ set organisation-prosociality 1.2 ] ]
end

;; -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;; 2. Groups procedures
;; -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

to update-instrumental-motivation-groups
  ask organisations [
    let levels n-levels
    let inst-mot organisation-instrumental-motivation
    ask my-groups with [ group-level-id = 1 ] [
     ; set group-instrumental-motivation round ( ( ( inst-mot ) + group-normative-motivation ) / 2 ) ;; average instead of the bias with multiplication factor
       set group-instrumental-motivation round ( ( ( group-weight-inst * inst-mot ) + group-weight-norm * group-normative-motivation ) ) ;; average instead of the bias with multiplication factor
      let i 2
      while [i <= levels] [
        ask groups with [ organisation-id = [ who ] of myself and group-level-id = i ]
        [
          ;set group-instrumental-motivation round ( ( ( one-of [ group-instrumental-motivation ] of groups with [ ( organisation-id = [organisation-id] of myself ) and ( group-level-id = ( i - 1 ) ) ] ) + group-normative-motivation ) / 2 )
          set group-instrumental-motivation round ( ( ( group-weight-inst * ( one-of [ group-instrumental-motivation ] of groups with [ ( organisation-id = [organisation-id] of myself ) and ( group-level-id = ( i - 1 ) ) ] ) ) + group-weight-norm * group-normative-motivation ) )
          set group-instrumental-motivation verify-boundaries group-instrumental-motivation
          set group-average-instrumental-motivation butlast group-average-instrumental-motivation
          set group-average-instrumental-motivation fput group-instrumental-motivation group-average-instrumental-motivation
        ]
        set i i + 1
      ]
    ]
  ]
end

to update-normative-motivation-groups
  ask groups [ ;;;; first they need to update their own normative motivations and then progress that to the group!
    let mean-normative-motivation mean [ individual-power * individual-normative-motivation ] of my-individuals
    set group-normative-motivation round ( mean-normative-motivation * group-prosociality )
    set group-normative-motivation verify-boundaries group-normative-motivation
  ]

  ask organisations [
    let i n-levels ; the amount of levels the organisation has in its structure
    while [ i > 1 ] [
      let n-motivation-of-lvl 0
      let b [ group-normative-motivation ] of my-groups with [ group-level-id = i ]
      let a length b
      set n-motivation-of-lvl int ( reduce + b ) / a
      let id 0
      let powers 0
      ask one-of my-groups with [ group-level-id = i ] [ set id who ]
      set powers [ group-power ] of group id
      ask my-groups with [  group-level-id = ( i - 1 ) ] [
        set group-normative-motivation round ( ( ( 2 - powers ) * group-normative-motivation + powers * n-motivation-of-lvl ) ) / 2
        set group-normative-motivation verify-boundaries group-normative-motivation
      ]
      set i i - 1
    ]
  ]
end

to setup-group-prosociality
    ifelse external-competition = "low" [set group-prosociality 1.2]
    [ifelse external-competition = "medium" [set group-prosociality 1]
      [set group-prosociality 0.8]]
end

to allocate-power-groups
    ifelse organisational-structure = 2 [
      ask my-groups
      [
        set group-power 1
      ]
    ]
    [
      let i n-levels
      ask my-groups
      [
        set group-power ( 1.2 - ( group-level-id / i ) ^ 2 )
        if group-power > 1 [ set group-power 1 ]
      ]
    ]
end



;; -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;; 3. Individuals procedures
;; -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

;; Update instrumental motivation of all individuals
to update-instrumental-motivation-individuals
  ask individuals [
    set individual-instrumental-motivation round ( ( weight-inst * ( [group-instrumental-motivation] of group group-id ) + weight-norm * ( individual-normative-motivation ) ) )
    set individual-instrumental-motivation verify-boundaries individual-instrumental-motivation
  ]
end

;; Update normative motivation of all individuals
to update-normative-motivation-individuals

  ask groups [
    let average-individual-instrumental-motivation 0
    set average-individual-instrumental-motivation reduce + group-average-instrumental-motivation / internalisation-time

    ask my-individuals [
       set individual-normative-motivation ((individual-normative-motivation + ((average-individual-instrumental-motivation - individual-instrumental-motivation)
       / average-individual-instrumental-motivation)) * support-for-sustainable-behaviour)
      set individual-normative-motivation verify-boundaries individual-normative-motivation
    ]
  ]
end

to allocate-power-individuals
  ask my-groups [
    let status false
    while [ status = false ] [
      ask my-individuals [
        set individual-power random-gamma 4.0 4.0
      ]
        if mean [ individual-power ] of my-individuals > 0.9 and mean [ individual-power ] of my-individuals < 1.1 [
          set status true
        ]
      ]
    ]
end


;; -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;; 4. Envirorment procedures
;; -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
to setup-market-trend
  set effective-market-size 0
  set total-market-size 0
  ask organisations [
    set n-individuals ( random 1000 ) + N-INDIVIDUALS-PER-GROUP
    set n-groups ceiling (n-individuals / N-INDIVIDUALS-PER-GROUP)
    set org-size n-groups * N-INDIVIDUALS-PER-GROUP
    set investment-decision one-of [ 0 1 ]
    set effective-market-size ( effective-market-size +  investment-decision * org-size )
    set total-market-size ( total-market-size + org-size )

    ;; Visualization setup
    setxy 0.8 * (random xcor + size) 0.70 * (random ycor + size)
    set size ((6 + (n-groups / 8) + (n-groups * n-individuals / 4000 ) ) * 3 ) + 3
    repeat 1000 [ layout ]
    set hidden? true
  ]
  set market-trend effective-market-size / total-market-size
  set past-trend n-values organisation-memory [market-trend]

end

to update-market-trend
  ifelse (count organisations with [clock mod 20 = 0] ) != 0 and (count organisations with [investment-decision = 1]) != 0
  [
    set market-trend ((reduce + [org-size] of organisations with [investment-decision = 1])  / (reduce + [org-size] of organisations with [clock mod 20 = 0]))
    set past-trend butlast past-trend
    set past-trend fput market-trend past-trend
  ]
  [
    set market-trend one-of past-trend
    set past-trend butlast past-trend
    set past-trend fput ( market-trend * 0.9 ) past-trend
  ]
end


;; -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;; 0. Supplementary procedures
;; -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
to setup-globals
  ;; Global constants
  set WEIGHT-INSTRUMENTAL 0.7
  set WEIGHT-NORMATIVE 0.3
  set IMPROVEMENT 10
  set DEMOTIVATION 30
  set N-INDIVIDUALS-PER-GROUP 25
  set BRANDS [["non-sustainable" 0] ["marginally-sustainable" 0.25] ["moderately-sustainable" 0.5] ["quite-sustainable" 0.75] ["sustainable corresponding" 1]]
  set sixteen-personalities [ 0.138 0.123 0.116 0.088 0.087 0.085 0.054 0.044 0.043 0.033 0.032 0.025 0.021 0.018 0.015 ]
  setup-organisational-structure-distribution
end

to-report verify-boundaries [motivation]
  ifelse motivation < 1
  [
    set motivation 1
  ]
  [
    if motivation > 100
    [
      set motivation 100
    ]
  ]
  report motivation
end

;;
to setup-organisational-structure-distribution
  set n-hierarchical round (percentage-hierarchical * n-organisations)
  set n-intermediate round (percentage-intermediate * n-organisations)
  set n-flat round (percentage-flat * n-organisations)
  set n-organisations ( n-flat +  n-hierarchical + n-intermediate )
end


;;
to select-organisational-structure
  ifelse n-hierarchical >= 1 [
    set organisational-structure 2
    ;set n-levels n-groups
    set n-hierarchical n-hierarchical - 1
  ]
  [
    ifelse n-intermediate >= 1 [
      set organisational-structure 1
      ;set n-levels round n-groups / 2 ;; start with subtracting 1 from n groups, then substract 2, then 3, and so on to find the number of levels
      ;calculate-levels-intermediate
      set n-intermediate n-intermediate - 1
    ]
    [
      if n-flat >= 1 [
        set organisational-structure 0
        ;set n-levels 1
        set n-flat n-flat - 1
      ]
    ]
  ]
end

to setup-personalities
  let dist-personalities map [ i -> round ( total-market-size * i ) ] sixteen-personalities
  let types-personalities [ "ISFJ" "ESFJ" "ISTJ" "ISFP" "ESTJ" "ESFP" "ENFP" "ISTP" "INFP" "ESTP" "INTP" "ENTP" "ENFJ" "INTJ" "ENTJ" "ENFJ" ]
  let weight-dist [ 0.825 0.175 0.775 0.225 0.625 0.375 0.825 0.175 0.475 0.525 0.775 0.225 0.375 0.625 0.675 0.325 0.325 0.675 0.625 0.375 0.275 0.775 0.675 0.325 0.325 0.675 0.275 0.725 0.625 0.375 ]
  let nr-individuals total-market-size
  while [ empty? [ 0 ] of individuals with [ personality = "NONE" ] = false ] [
    ifelse nr-individuals >= item 0 dist-personalities and length dist-personalities > 1 [
      ask n-of (  item 0 dist-personalities ) individuals with [ personality = "NONE" ] [
        set personality item 0 types-personalities
        set weight-inst item 0 weight-dist
        set weight-norm item 1 weight-dist
      ]
      set nr-individuals nr-individuals - item 0 dist-personalities
      set types-personalities butfirst types-personalities
      set dist-personalities butfirst dist-personalities
      set weight-dist butfirst butfirst weight-dist
    ]
    [
      ask n-of nr-individuals individuals with [ personality = "NONE" ] [
        set personality item 0 types-personalities
        set weight-inst item 0 weight-dist
        set weight-norm item 1 weight-dist
      ]
    ]
  ]
end

to setup-weights-groups-and-organisations
  ask groups [
    set group-weight-inst mean [ weight-inst ] of my-individuals
    set group-weight-norm mean [ weight-norm ] of my-individuals
  ]
  ask organisations [
    set organisation-weight-inst mean [ group-weight-inst ] of my-groups with [ group-level-id <= 2 ]
    set organisation-weight-norm mean [ group-weight-norm ] of my-groups with [ group-level-id <= 2 ]
  ]
end

to assign-groups-to-level
  set n-levels 0
  let remaining n-groups
  let n 1
  let i 1

  while [ empty? [ 0 ] of groups with [ group-level-id = 0 and organisation-id = [ who ] of myself ] = false ] [
    ifelse organisational-structure = 2 [
      ask groups with [ group-level-id = 0 and organisation-id = [ who ] of myself ] [
        set group-level-id 1
        set group-power 1
      ]
      set i i + 1
    ]

    [ ifelse organisational-structure = 1 [
      ifelse ( n )  < remaining [
        ask n-of n groups with [ group-level-id = 0 and organisation-id = [ who ] of myself ] [
          set group-level-id i
          set group-power 1
        ]
      ]
      [
        ask n-of remaining groups with [ group-level-id = 0 and organisation-id = [ who ] of myself ] [
          set group-level-id i
          set group-power 1
        ]
      ]
      set i i + 1
      set remaining remaining - n
      set n 3 * n
      ]

      [ ifelse ( n )  < remaining [
        ask n-of n groups with [ group-level-id = 0 and organisation-id = [ who ] of myself ] [
          set group-level-id i
          set group-power 1
        ]
        ]
        [
          ask n-of remaining groups with [ group-level-id = 0 and organisation-id = [ who ] of myself ] [
            set group-level-id i
            set group-power 1
            ;write 5
          ]
        ]

        set i i + 1
        set remaining remaining - n
        set n 2 * n
      ]
    ]
  ]
  set n-levels i - 1
end

to layout
  layout-spring organisations links 6 8 8
end

to setup-legend
  ask patches with [pycor < 200 and pycor > 185 and pxcor > -150 and pxcor < 150 ] [
     set pcolor palette:scale-scheme "Divergent" "RdYlGn" 10 (round pxcor) (min-pxcor) (max-pxcor)
  ]
end

to setup-visualization

  ask organisations [

    let organisation-instrumental-motivation-temp organisation-instrumental-motivation
;    let max-organisation-instrumental-motivation-temp max [organisation-instrumental-motivation] of organisations
;    show max-organisation-instrumental-motivation-temp

    let organisation-normative-motivation-temp organisation-normative-motivation
;    let max-organisation-normative-motivation-temp max [organisation-normative-motivation] of organisations
;    show max-organisation-normative-motivation-temp

    let average-group-instrumental-motivation-temp mean [group-instrumental-motivation] of my-groups
;    let max-group-instrumental-motivation-temp max [group-instrumental-motivation] of groups
;    show max-group-instrumental-motivation-temp

    let average-individuals-instrumental-motivation-temp mean [individual-instrumental-motivation] of individuals with [ (organisation-id = [who] of myself)]
;    let max-individuals-instrumental-motivation-temp max [individual-instrumental-motivation] of individuals
;    show max-individuals-instrumental-motivation-temp

;    let max-group-normative-motivation-temp max [group-normative-motivation] of groups
;    show max-group-normative-motivation-temp
;    let max-individuals-normative-motivation-temp max [individual-normative-motivation] of individuals
;    show max-individuals-normative-motivation-temp

    let halo-levels 3
    let core-size 6
    let core-size-2 (core-size + (n-groups / 8) )
    let core-size-3 (core-size-2 + (n-groups * n-individuals / 4000 ) )

    let halos-counter 1
    let prev-size patches in-radius (0)

    hatch-halos halo-levels
    [
      set hidden? false
      set organisation-id [who] of myself
      ifelse halos-counter = 1
      [
        set core-id 1
        set size (halos-counter) * core-size
        set color palette:scale-scheme "Divergent" "RdYlGn" 10 organisation-instrumental-motivation-temp 0 100
        __set-line-thickness 0.5
        ask patches in-radius ((size * 0.5) - 1) with [not member? self prev-size]
        [
          set pcolor palette:scale-scheme "Divergent" "RdYlGn" 10 organisation-normative-motivation-temp 0 100
        ]
      ]
      [
        ifelse halos-counter = 2
        [
          set core-id 2
          set size (halos-counter) * (core-size-2)
          set color palette:scale-scheme "Divergent" "RdYlGn" 10 average-group-instrumental-motivation-temp 0 100
          __set-line-thickness 0.5

          let my-patches patches in-radius ((size * 0.5) - 1) with [not member? self prev-size]
          ask [my-groups] of myself
          [
            set hidden? false
            set size 3
            set color palette:scale-scheme "Divergent" "RdYlGn" 10 group-normative-motivation 0 100
            move-to one-of my-patches
          ]
        ]
        [
          set core-id 3
          set size (halos-counter) * (core-size-3)

          set color palette:scale-scheme "Divergent" "RdYlGn" 10 average-individuals-instrumental-motivation-temp 0 100
          __set-line-thickness 0.5

          let my-patches patches in-radius ((size * 0.5) - 1) with [not member? self prev-size]
          ask [my-groups] of myself
          [

            ask my-individuals
            [
              set hidden? false
              set color palette:scale-scheme "Divergent" "RdYlGn" 10 individual-normative-motivation 0 100
              set size 1
              move-to one-of my-patches
            ]
          ]

        ]
      ]
      set halos-counter halos-counter + 1
      set prev-size patches in-radius ((size * 0.5) + 1)
    ]
    set my-halos halos with [ (organisation-id = [who] of myself)]
  ]
  setup-legend
end

to update-instrumental-motivation-organisations-visualization
;  let max-organisation-instrumental-motivation-temp max [organisation-instrumental-motivation] of organisations
;  show max-organisation-instrumental-motivation-temp

  ask organisations
  [
    let organisation-instrumental-motivation-temp organisation-instrumental-motivation
    ask my-halos with [core-id = 1]
    [
;      show "yes"
      set color palette:scale-scheme "Divergent" "RdYlGn" 10 organisation-instrumental-motivation-temp 0 100
    ]
  ]
end

to update-normative-motivation-organisations-visualization
;  let max-organisation-normative-motivation-temp max [organisation-normative-motivation] of organisations
;  show max-organisation-normative-motivation-temp

  ask organisations
  [
    let organisation-normative-motivation-temp organisation-normative-motivation
;    show organisation-normative-motivation-temp
    ask my-halos with [core-id = 1]
    [

      ask patches in-radius ((size * 0.5) - 1)
          [
            set pcolor palette:scale-scheme "Divergent" "RdYlGn" 10 organisation-normative-motivation-temp 0 100
      ]
    ]
  ]
end

to update-instrumental-motivation-groups-visualization
;  let max-group-instrumental-motivation-temp max [group-instrumental-motivation] of groups
;  show max-group-instrumental-motivation-temp

  ask organisations [
    let average-group-instrumental-motivation-temp mean [group-instrumental-motivation] of my-groups
    ask my-halos with [core-id = 2]
    [
      ;show "yes"
      set color palette:scale-scheme "Divergent" "RdYlGn" 10 average-group-instrumental-motivation-temp 0 100
    ]
  ]
end

to update-normative-motivation-groups-visualization
;  let max-group-normative-motivation-temp max [group-normative-motivation] of groups
;  show max-group-normative-motivation-temp

  ask groups
  [
    set color palette:scale-scheme "Divergent" "RdYlGn" 10 group-normative-motivation 0 100
  ]

end

to update-instrumental-motivation-individuals-visualization
;  let max-individuals-instrumental-motivation-temp max [individual-instrumental-motivation] of individuals
;  show max-individuals-instrumental-motivation-temp

  ask organisations [
    let average-individuals-instrumental-motivation-temp mean [individual-instrumental-motivation] of individuals with [ (organisation-id = [who] of myself)]
    ask my-halos with [core-id = 3]
    [
;      show "yes"
      set color palette:scale-scheme "Divergent" "RdYlGn" 10 average-individuals-instrumental-motivation-temp 0 100
    ]
  ]
end

to update-normative-motivation-individuals-visualization
;  let max-individuals-normative-motivation-temp max [individual-normative-motivation] of individuals
;  show max-individuals-normative-motivation-temp
  ask individuals
  [
    set color palette:scale-scheme "Divergent" "RdYlGn" 10 individual-normative-motivation 0 100
  ]

end
@#$#@#$#@
GRAPHICS-WINDOW
19
523
1217
1722
-1
-1
2.97
1
10
1
1
1
0
1
1
1
-200
200
-200
200
0
0
1
ticks
30.0

BUTTON
20
22
86
55
NIL
setup
NIL
1
T
OBSERVER
NIL
1
NIL
NIL
1

CHOOSER
22
418
152
463
external-competition
external-competition
"high" "medium" "low"
0

SLIDER
18
156
268
189
subsidy
subsidy
0.8
1.5
1.5
0.1
1
dmnl
HORIZONTAL

SLIDER
17
198
269
231
tax
tax
0
0.5
0.5
0.1
1
dmnl
HORIZONTAL

SLIDER
18
239
270
272
support-for-sustainable-behaviour
support-for-sustainable-behaviour
0.9
1.5
0.9
0.1
1
dmnl
HORIZONTAL

SLIDER
18
73
268
106
n-organisations
n-organisations
3
20
20.0
1
1
organisation
HORIZONTAL

BUTTON
169
22
232
55
NIL
go
T
1
T
OBSERVER
NIL
3
NIL
NIL
1

BUTTON
95
22
158
55
NIL
go
NIL
1
T
OBSERVER
NIL
2
NIL
NIL
1

SLIDER
18
116
268
149
threshold
threshold
0
100
20.0
1
1
dmnl
HORIZONTAL

PLOT
927
35
1127
185
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
722
345
1128
504
average-individual-motivation
ticks
NIL
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"indv-norm-mot" 1.0 0 -14454117 true "" "plot ( reduce + [ individual-normative-motivation ] of individuals ) / count individuals"
"indv-inst-mot" 1.0 0 -12087248 true "" "plot ( reduce + [ individual-instrumental-motivation ] of individuals ) / count individuals"

PLOT
721
35
921
185
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
"default" 1.0 0 -16777216 true "" "plot ( sum [ brand ] of organisations ) / n-organisations"

MONITOR
1132
34
1211
79
brand 1
count organisations with [ brand = 1 ]
17
1
11

MONITOR
1132
86
1213
131
brand 0.75
count organisations with [ brand = 0.75 ]
17
1
11

MONITOR
1134
139
1215
184
brand 0.5
count organisations with [ brand = 0.5 ]
17
1
11

MONITOR
1133
192
1214
237
brand 0.25
count organisations with [ brand = 0.25 ]
17
1
11

MONITOR
1133
242
1215
287
brand 0
count organisations with [ brand = 0 ]
17
1
11

SLIDER
20
289
241
322
organisation-memory
organisation-memory
1
40
40.0
1
1
ticks
HORIZONTAL

PLOT
721
192
921
333
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

PLOT
927
193
1127
333
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
20
331
239
364
variance-normative-motivation
variance-normative-motivation
0
20
20.0
1
1
NIL
HORIZONTAL

INPUTBOX
436
73
571
133
percentage-hierarchical
0.5
1
0
Number

INPUTBOX
578
74
710
134
percentage-intermediate
0.3
1
0
Number

INPUTBOX
294
73
427
133
percentage-flat
0.2
1
0
Number

SWITCH
295
24
398
57
Visual?
Visual?
1
1
-1000

SLIDER
21
371
240
404
internalisation-time
internalisation-time
1
40
20.0
1
1
NIL
HORIZONTAL

TEXTBOX
185
539
341
562
Least sustainable
20
0.0
1

TEXTBOX
902
538
1052
563
Most sustainable
20
0.0
1

PLOT
339
193
714
333
average-organisations-motivation
ticks
NIL
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"org-norm-mot" 1.0 0 -14454117 true "" "plot ( reduce + [ organisation-normative-motivation ] of organisations ) / n-organisations"
"org-inst-mot" 1.0 0 -14439633 true "" "plot ( reduce + [ organisation-instrumental-motivation ] of organisations ) / n-organisations"

PLOT
340
344
716
504
average-groups-motivation
NIL
NIL
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"group-norm-mot" 1.0 0 -12345184 true "" "plot ( reduce + [ group-normative-motivation ] of groups ) / count groups"
"group-inst-mot" 1.0 0 -12087248 true "" "plot ( reduce + [ group-instrumental-motivation ] of groups ) / count groups"

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

thin ring
true
0
Circle -7500403 false true -1 -1 301

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
NetLogo 6.0.3
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment all" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>( reduce + [ organisation-normative-motivation ] of organisations ) / n-organisations</metric>
    <metric>( reduce + [ organisation-instrumental-motivation ] of organisations ) / n-organisations</metric>
    <metric>( reduce + [ group-normative-motivation ] of groups ) / count groups</metric>
    <metric>( reduce + [ group-instrumental-motivation ] of groups ) / count groups</metric>
    <metric>( reduce + [ individual-normative-motivation ] of individuals ) / count individuals</metric>
    <metric>( reduce + [ individual-instrumental-motivation ] of individuals ) / count individuals</metric>
    <metric>count organisations with [ brand = 1 ]</metric>
    <metric>count organisations with [ brand = 0.75 ]</metric>
    <metric>count organisations with [ brand = 0.5 ]</metric>
    <metric>count organisations with [ brand = 0.25 ]</metric>
    <metric>count organisations with [ brand = 0 ]</metric>
    <enumeratedValueSet variable="tax">
      <value value="0"/>
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.4"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy">
      <value value="1"/>
      <value value="1.2"/>
      <value value="1.3"/>
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="external-competition">
      <value value="&quot;high&quot;"/>
      <value value="&quot;medium&quot;"/>
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threshold">
      <value value="10"/>
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
      <value value="85"/>
      <value value="90"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="support-for-sustainable-behaviour">
      <value value="0.9"/>
      <value value="1"/>
      <value value="1.2"/>
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="organisation-memory">
      <value value="10"/>
      <value value="20"/>
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="internalisation-time">
      <value value="10"/>
      <value value="20"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment company-behaviour" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>( reduce + [ organisation-normative-motivation ] of organisations ) / n-organisations</metric>
    <metric>( reduce + [ organisation-instrumental-motivation ] of organisations ) / n-organisations</metric>
    <metric>( reduce + [ group-normative-motivation ] of groups ) / count groups</metric>
    <metric>( reduce + [ group-instrumental-motivation ] of groups ) / count groups</metric>
    <metric>( reduce + [ individual-normative-motivation ] of individuals ) / count individuals</metric>
    <metric>( reduce + [ individual-instrumental-motivation ] of individuals ) / count individuals</metric>
    <metric>count organisations with [ brand = 1 ]</metric>
    <metric>count organisations with [ brand = 0.75 ]</metric>
    <metric>count organisations with [ brand = 0.5 ]</metric>
    <metric>count organisations with [ brand = 0.25 ]</metric>
    <metric>count organisations with [ brand = 0 ]</metric>
    <enumeratedValueSet variable="threshold">
      <value value="10"/>
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
      <value value="85"/>
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="organisation-memory">
      <value value="5"/>
      <value value="10"/>
      <value value="20"/>
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="internalisation-time">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment external uncertainties" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>( reduce + [ organisation-normative-motivation ] of organisations ) / n-organisations</metric>
    <metric>( reduce + [ organisation-instrumental-motivation ] of organisations ) / n-organisations</metric>
    <metric>( reduce + [ group-normative-motivation ] of groups ) / count groups</metric>
    <metric>( reduce + [ group-instrumental-motivation ] of groups ) / count groups</metric>
    <metric>( reduce + [ individual-normative-motivation ] of individuals ) / count individuals</metric>
    <metric>( reduce + [ individual-instrumental-motivation ] of individuals ) / count individuals</metric>
    <metric>count organisations with [ brand = 1 ]</metric>
    <metric>count organisations with [ brand = 0.75 ]</metric>
    <metric>count organisations with [ brand = 0.5 ]</metric>
    <metric>count organisations with [ brand = 0.25 ]</metric>
    <metric>count organisations with [ brand = 0 ]</metric>
    <enumeratedValueSet variable="external-competition">
      <value value="&quot;high&quot;"/>
      <value value="&quot;medium&quot;"/>
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="support-for-sustainable-behaviour">
      <value value="0.9"/>
      <value value="0.95"/>
      <value value="1"/>
      <value value="1.1"/>
      <value value="1.2"/>
      <value value="1.3"/>
      <value value="1.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment tax" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>( reduce + [ organisation-normative-motivation ] of organisations ) / n-organisations</metric>
    <metric>( reduce + [ organisation-instrumental-motivation ] of organisations ) / n-organisations</metric>
    <metric>( reduce + [ group-normative-motivation ] of groups ) / count groups</metric>
    <metric>( reduce + [ group-instrumental-motivation ] of groups ) / count groups</metric>
    <metric>( reduce + [ individual-normative-motivation ] of individuals ) / count individuals</metric>
    <metric>( reduce + [ individual-instrumental-motivation ] of individuals ) / count individuals</metric>
    <metric>count organisations with [ brand = 1 ]</metric>
    <metric>count organisations with [ brand = 0.75 ]</metric>
    <metric>count organisations with [ brand = 0.5 ]</metric>
    <metric>count organisations with [ brand = 0.25 ]</metric>
    <metric>count organisations with [ brand = 0 ]</metric>
    <enumeratedValueSet variable="tax">
      <value value="0"/>
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.4"/>
      <value value="0.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment subsidy" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>( reduce + [ organisation-normative-motivation ] of organisations ) / n-organisations</metric>
    <metric>( reduce + [ organisation-instrumental-motivation ] of organisations ) / n-organisations</metric>
    <metric>( reduce + [ group-normative-motivation ] of groups ) / count groups</metric>
    <metric>( reduce + [ group-instrumental-motivation ] of groups ) / count groups</metric>
    <metric>( reduce + [ individual-normative-motivation ] of individuals ) / count individuals</metric>
    <metric>( reduce + [ individual-instrumental-motivation ] of individuals ) / count individuals</metric>
    <metric>count organisations with [ brand = 1 ]</metric>
    <metric>count organisations with [ brand = 0.75 ]</metric>
    <metric>count organisations with [ brand = 0.5 ]</metric>
    <metric>count organisations with [ brand = 0.25 ]</metric>
    <metric>count organisations with [ brand = 0 ]</metric>
    <enumeratedValueSet variable="subsidy">
      <value value="1"/>
      <value value="1.2"/>
      <value value="1.3"/>
      <value value="1.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment external-competition" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>( reduce + [ organisation-normative-motivation ] of organisations ) / n-organisations</metric>
    <metric>( reduce + [ organisation-instrumental-motivation ] of organisations ) / n-organisations</metric>
    <metric>( reduce + [ group-normative-motivation ] of groups ) / count groups</metric>
    <metric>( reduce + [ group-instrumental-motivation ] of groups ) / count groups</metric>
    <metric>( reduce + [ individual-normative-motivation ] of individuals ) / count individuals</metric>
    <metric>( reduce + [ individual-instrumental-motivation ] of individuals ) / count individuals</metric>
    <metric>count organisations with [ brand = 1 ]</metric>
    <metric>count organisations with [ brand = 0.75 ]</metric>
    <metric>count organisations with [ brand = 0.5 ]</metric>
    <metric>count organisations with [ brand = 0.25 ]</metric>
    <metric>count organisations with [ brand = 0 ]</metric>
    <enumeratedValueSet variable="external-competition">
      <value value="&quot;high&quot;"/>
      <value value="&quot;medium&quot;"/>
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment threshold" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>( reduce + [ organisation-normative-motivation ] of organisations ) / n-organisations</metric>
    <metric>( reduce + [ organisation-instrumental-motivation ] of organisations ) / n-organisations</metric>
    <metric>( reduce + [ group-normative-motivation ] of groups ) / count groups</metric>
    <metric>( reduce + [ group-instrumental-motivation ] of groups ) / count groups</metric>
    <metric>( reduce + [ individual-normative-motivation ] of individuals ) / count individuals</metric>
    <metric>( reduce + [ individual-instrumental-motivation ] of individuals ) / count individuals</metric>
    <metric>count organisations with [ brand = 1 ]</metric>
    <metric>count organisations with [ brand = 0.75 ]</metric>
    <metric>count organisations with [ brand = 0.5 ]</metric>
    <metric>count organisations with [ brand = 0.25 ]</metric>
    <metric>count organisations with [ brand = 0 ]</metric>
    <enumeratedValueSet variable="threshold">
      <value value="10"/>
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
      <value value="85"/>
      <value value="90"/>
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment SSB" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>( reduce + [ organisation-normative-motivation ] of organisations ) / n-organisations</metric>
    <metric>( reduce + [ organisation-instrumental-motivation ] of organisations ) / n-organisations</metric>
    <metric>( reduce + [ group-normative-motivation ] of groups ) / count groups</metric>
    <metric>( reduce + [ group-instrumental-motivation ] of groups ) / count groups</metric>
    <metric>( reduce + [ individual-normative-motivation ] of individuals ) / count individuals</metric>
    <metric>( reduce + [ individual-instrumental-motivation ] of individuals ) / count individuals</metric>
    <metric>count organisations with [ brand = 1 ]</metric>
    <metric>count organisations with [ brand = 0.75 ]</metric>
    <metric>count organisations with [ brand = 0.5 ]</metric>
    <metric>count organisations with [ brand = 0.25 ]</metric>
    <metric>count organisations with [ brand = 0 ]</metric>
    <enumeratedValueSet variable="support-for-sustainable-behaviour">
      <value value="0.9"/>
      <value value="1"/>
      <value value="1.1"/>
      <value value="1.2"/>
      <value value="1.3"/>
      <value value="1.4"/>
      <value value="1.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment memory" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>( reduce + [ organisation-normative-motivation ] of organisations ) / n-organisations</metric>
    <metric>( reduce + [ organisation-instrumental-motivation ] of organisations ) / n-organisations</metric>
    <metric>( reduce + [ group-normative-motivation ] of groups ) / count groups</metric>
    <metric>( reduce + [ group-instrumental-motivation ] of groups ) / count groups</metric>
    <metric>( reduce + [ individual-normative-motivation ] of individuals ) / count individuals</metric>
    <metric>( reduce + [ individual-instrumental-motivation ] of individuals ) / count individuals</metric>
    <metric>count organisations with [ brand = 1 ]</metric>
    <metric>count organisations with [ brand = 0.75 ]</metric>
    <metric>count organisations with [ brand = 0.5 ]</metric>
    <metric>count organisations with [ brand = 0.25 ]</metric>
    <metric>count organisations with [ brand = 0 ]</metric>
    <enumeratedValueSet variable="organisation-memory">
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
      <value value="30"/>
      <value value="40"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment internalisation-time" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>( reduce + [ organisation-normative-motivation ] of organisations ) / n-organisations</metric>
    <metric>( reduce + [ organisation-instrumental-motivation ] of organisations ) / n-organisations</metric>
    <metric>( reduce + [ group-normative-motivation ] of groups ) / count groups</metric>
    <metric>( reduce + [ group-instrumental-motivation ] of groups ) / count groups</metric>
    <metric>( reduce + [ individual-normative-motivation ] of individuals ) / count individuals</metric>
    <metric>( reduce + [ individual-instrumental-motivation ] of individuals ) / count individuals</metric>
    <metric>count organisations with [ brand = 1 ]</metric>
    <metric>count organisations with [ brand = 0.75 ]</metric>
    <metric>count organisations with [ brand = 0.5 ]</metric>
    <metric>count organisations with [ brand = 0.25 ]</metric>
    <metric>count organisations with [ brand = 0 ]</metric>
    <enumeratedValueSet variable="internalisation-time">
      <value value="5"/>
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment policies" repetitions="40" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>( reduce + [ organisation-normative-motivation ] of organisations ) / n-organisations</metric>
    <metric>( reduce + [ organisation-instrumental-motivation ] of organisations ) / n-organisations</metric>
    <metric>( reduce + [ group-normative-motivation ] of groups ) / count groups</metric>
    <metric>( reduce + [ group-instrumental-motivation ] of groups ) / count groups</metric>
    <metric>( reduce + [ individual-normative-motivation ] of individuals ) / count individuals</metric>
    <metric>( reduce + [ individual-instrumental-motivation ] of individuals ) / count individuals</metric>
    <metric>count organisations with [ brand = 1 ]</metric>
    <metric>count organisations with [ brand = 0.75 ]</metric>
    <metric>count organisations with [ brand = 0.5 ]</metric>
    <metric>count organisations with [ brand = 0.25 ]</metric>
    <metric>count organisations with [ brand = 0 ]</metric>
    <enumeratedValueSet variable="tax">
      <value value="0"/>
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.4"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy">
      <value value="1"/>
      <value value="1.2"/>
      <value value="1.3"/>
      <value value="1.5"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
