#import "utils.typ"

// set rules
#let setrules(settings, doc) = {
    set text(
        font: settings.bodyfont,
        size: settings.fontsize,
        hyphenate: false,
    )

    set list(
        spacing: settings.linespacing
    )

    set par(
        leading: settings.linespacing,
        justify: true,
    )

    show link: it => {
        text(
            fill: settings.hyperlink_color,
        )[#it]
    }

    doc
}

// show rules
#let showrules(settings, doc) = {
    // Uppercase section headings
    show heading.where(
        level: 2,
    ): it => block(width: 100%)[
        #v(settings.sectionspacing)
        #set align(left)
        #set text(font: settings.headingfont, size: 1em, weight: "semibold")
        #if (settings.at("headingsmallcaps", default:false)) {
            smallcaps(it.body)
        } else {
            it.body
        }
        #v(-0.75em) #line(length: 100%, stroke: 1pt + black) // draw a line
    ]

    // Name title/heading
    show heading.where(
        level: 1,
    ): it => block(width: 100%)[
        #set text(font: settings.headingfont, size: 1.1em, weight: "semibold")
        #if (settings.at("headingsmallcaps", default:false)) {
            smallcaps(it.body)
        } else {
            it.body
        }
        #v(2pt)
    ]

    doc
}

// Set page layout
#let cvinit(doc) = {
    doc = setrules(doc)
    doc = showrules(doc)

    doc
}

// Job titles
#let jobtitletext(info, settings) = {
    if ("titles" in info.personal and info.personal.titles != none) and settings.show_title {
        block(width: 100%)[
            #text(weight: "semibold", info.personal.titles.join("  /  "))
            #v(-4pt)
        ]
    } else {none}
}

// Address
#let addresstext(info, settings) = {
    if ("location" in info.personal and info.personal.location != none) and settings.show_address {
        // Filter out empty address fields
        let address = info.personal.location.pairs().filter(it => it.at(1) != none and str(it.at(1)) != "")
        // Join non-empty address fields with commas
        let location = address.map(it => str(it.at(1))).join(", ")

        block(width: 100%)[
            #location
            #v(-4pt)
        ]
    } else {none}
}

#let contacttext(info, settings) = block(width: 100%)[
    #let profiles = (
        if "email" in info.personal and info.personal.email != none { box(link("mailto:" + info.personal.email)) },
        if ("phone" in info.personal and info.personal.phone != none) and settings.show_number {box(link("tel:" + info.personal.phone))} else {none},
        if ("url" in info.personal) and (info.personal.url != none) {
            box(link(info.personal.url)[#info.personal.url.split("//").at(1)])
        }
    ).filter(it => it != none) // Filter out none elements from the profile array

    #if ("profiles" in info.personal) and (info.personal.profiles.len() > 0) {
        for profile in info.personal.profiles {
            profiles.push(
                box(link(profile.url)[#profile.url.split("//").at(1)])
            )
        }
    }

    #set text(font: settings.bodyfont, weight: "medium", size: settings.fontsize)
    #pad(x: 0em)[
        #profiles.join([#sym.space.en | #sym.space.en])
    ]
]

#let cvheading(info, settings) = {
    align(center)[
        = #info.personal.name
        #jobtitletext(info, settings)
        // #addresstext(info, settings)
        #contacttext(info, settings)
    ]
}

// Individual Layout Functions
// ===========================
// layout_text
// layout_education
// start_time, end_time, institution, location, title

// layout_work
// institution, (sub_employer), advisor, description

// layout_publications
// citation (make it automatically bold the name)

// layout_presentations
// year, institution, place, title

// layout_awards
// year, institution, title

// layout_teaching
// year, position, course_title, (professor), description

#let layout_timeline_institution(data, isbreakable: true) = {
  let year_column_width = 7em
  let line_pos = year_column_width + 0.5em
  
  // Create the container with relative positioning for the line
  block(width: 100%, breakable: isbreakable, inset: 0pt, outset: 0pt)[
    
    // Content
    #for (i, edu) in data.enumerate() {
      let year_text = if "end_date" in edu and edu.end_date != none {
        if "start_date" in edu and edu.start_date != none {
          if edu.end_date == "present" or edu.end_date == "Present" {
            [#edu.start_date - Present]
          } else if edu.start_date == edu.end_date{
            [#edu.start_date]
          } else {
            [#edu.start_date - #edu.end_date]
          }
        } else {
          [#edu.end_date]
        }
      } else if "start_date" in edu and edu.start_date != none {
        [#edu.start_date]
      } else {
        []
      }
      
      // Create a grid for this entry
      grid(
        columns: (year_column_width, 1fr),
        gutter: 1em,
        
        // Year column (right-aligned)
        align(right)[#year_text],

        grid.vline(),
        
        // Institution details
        pad(left: 0.5em)[
            #if "institution" in edu and edu.institution != none {
                text(weight: "bold")[#edu.institution]
                if "location" in edu and edu.location != none {
                    [, #edu.location]
                }
                linebreak()
            }
            #if "title" in edu and edu.title != none [
                // #linebreak()
                #text(style: "italic")[#edu.title]
                #linebreak()
            ]
            #if "advisors" in edu and edu.advisors != none {
                // #linebreak()
                text(style: "italic")[
                    #if edu.advisors.len() == 1 [Advisor:] else [Advisors:]
                ] 
                text[
                    #if edu.advisors.len() == 1 [
                        #edu.advisors.at(0)
                    ] else if edu.advisors.len() == 2 [
                        #edu.advisors.at(0) and #edu.advisors.at(1)
                    ] else [
                        #for (i, advisor) in edu.advisors.enumerate() [
                            #if i == edu.advisors.len() - 1 [
                                and #advisor
                            ] else if i == edu.advisors.len() - 2 [
                                #advisor 
                            ] else [
                                #advisor, 
                            ]
                        ]
                    ]
                ]
                linebreak()
            }
            #if "description" in edu and edu.description != none {
                // v(0.02em)
                text(size: 8pt)[#edu.description]
            }
        ]
      )
      
      // Add space between entries except after the last one
      if i < data.len() - 1 {
        v(0.1em)
      }
    }
  ]
}

#let layout_timeline_title(data, isbreakable: true) = {
  let year_column_width = 7em
  let line_pos = year_column_width + 0.5em
  
  // Create the container with relative positioning for the line
  block(width: 100%, breakable: isbreakable, inset: 0pt, outset: 0pt)[
    
    // Content
    #for (i, edu) in data.enumerate() {
      let year_text = if "end_date" in edu and edu.end_date != none {
        if "start_date" in edu and edu.start_date != none {
          if edu.end_date == "present" or edu.end_date == "Present" {
            [#edu.start_date - Present]
          } else if edu.start_date == edu.end_date{
            [#edu.start_date]
          } else {
            [#edu.start_date - #edu.end_date]
          }
        } else {
          [#edu.end_date]
        }
      } else if "start_date" in edu and edu.start_date != none {
        [#edu.start_date]
      } else {
        []
      }
      
      // Create a grid for this entry
      grid(
        columns: (year_column_width, 1fr),
        gutter: 1em,
        
        // Year column (right-aligned)
        align(right)[#year_text],

        grid.vline(),
        
        // Institution details
        pad(left: 0.5em)[
            #if "title" in edu and edu.title != none {
                text(weight: "bold")[#edu.title]
                linebreak()
            }
            #if "institution" in edu and edu.institution != none [
                // #linebreak()
                #text(style: "italic")[#edu.institution]
                #linebreak()
            ]
            #if "professors" in edu and edu.professors != none {
                // #linebreak()
                text(style: "italic")[
                    #if edu.professors.len() == 1 [Professor:] else [Professors:]
                ] 
                text[
                    #if edu.professors.len() == 1 [
                        #edu.professors.at(0)
                    ] else if edu.professors.len() == 2 [
                        #edu.professors.at(0) and #edu.professors.at(1)
                    ] else [
                        #for (i, professor) in edu.professors.enumerate() [
                            #if i == edu.professors.len() - 1 [
                                and #professor
                            ] else if i == edu.professors.len() - 2 [
                                #professor 
                            ] else [
                                #professor, 
                            ]
                        ]
                    ]
                ]
                linebreak()
            }
            #if "description" in edu and edu.description != none {
                // v(0.02em)
                text(size: 8pt)[#edu.description]
            }
        ]
      )
      
      // Add space between entries except after the last one
      if i < data.len() - 1 {
        v(0.1em)
      }
    }
  ]
}

#let layout_numbered_list(data, isbreakable: true) = {
  // Set width for the number column
  let number_width = 2em
  
  block(width: 100%, breakable: isbreakable)[
    // Check if we have citations
    #if "citations" in data and data.citations != none {
      for (index, citation) in data.citations.enumerate() {
        // Create a grid with two columns
        grid(
          columns: (number_width, 1fr),
          gutter: 1em,
          
          // Right-aligned number in the first column
          align(right)[#(index + 1).],
          
          // Citation text with markup in the second column
          [#eval(citation, mode: "markup")]
        )
        
        // Add space between entries
        if index < data.citations.len() - 1 {
          v(0.05em)
        }
      }
    } else {
      [No publications found]
    }
  ]
}

// Publications layout
// #let layout_publications(data, isbreakable: true) = {
//     for pub in data {
//         // Parse ISO date strings into datetime objects
//         let date = utils.strpdate(pub.releaseDate)
//         // Create a block layout for each publication entry
//         block(width: 100%, breakable: isbreakable)[
//             // Line 1: Publication Title
//             #if pub.url != none [
//                 *#link(pub.url)[#pub.name]* \
//             ] else [
//                 *#pub.name* \
//             ]
//             // Line 2: Publisher and Date
//             #if pub.publisher != none [
//                 Published on #text(style: "italic")[#pub.publisher]  #h(1fr) #date \
//             ] else [
//                 In press \
//             ]
//         ]
//     }
// }

// Skills layout
#let layout_skills(data, languages, interests, isbreakable: true) = {
    block(breakable: isbreakable)[
        #if languages != none [
            #let langs = ()
            #for lang in languages {
                langs.push([#lang.language (#lang.fluency)])
            }
            - *Languages*: #langs.join(", ")
        ]
        #if data != none [
            #for group in data [
                - *#group.category*: #group.skills.join(", ")
            ]
        ]
        #if interests != none [
            - *Interests*: #interests.join(", ")
        ]
    ]
}

// References layout
#let layout_references(data, isbreakable: true) = {
    for ref in data {
        block(width: 100%, breakable: isbreakable)[
            #if ("url" in ref) and (ref.url != none) [
                - *#link(ref.url)[#ref.name]*: "#ref.reference"
            ] else [
                - *#ref.name*: "#ref.reference"
            ]
        ]
    }
}

// Main section rendering function
#let cvsection(info, layout: none, section: none, title: none, isbreakable: true) = {
    // Use the provided section, or default to the layout name if no section is specified
    let section_key = if section == none { layout } else { section }
    
    // Set default title based on layout type if not provided
    let section_title = title

    // Only render the section if it exists in the info data (skip title check for header)
    if ((section_key in info) and (info.at(section_key) != none)) or layout == "header" {
        // For header layout, don't add a section title
        if layout == "header" {
            layout_header(info.personal, isbreakable: isbreakable)
        } else {
            block[
                == #section_title
                
                // Use the appropriate layout function based on layout
                #if layout == "prose" {
                    layout_prose(info.at(section_key), isbreakable: isbreakable)
                } else if layout == "timeline_institution" {
                    layout_timeline_institution(info.at(section_key), isbreakable: isbreakable)
                } else if layout == "timeline_title" {
                    layout_timeline_title(info.at(section_key), isbreakable: isbreakable)
                } else if layout == "numbered_list" {
                    layout_numbered_list(info.at(section_key), isbreakable: isbreakable)
                } else {
                    [No layout function defined for "#layout"]
                }
            ]
        }
    } else {
        none
    }
}