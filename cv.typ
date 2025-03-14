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


// ----------------------------------- //
// ------------- Layouts ------------- //
// ----------------------------------- //

#let layout_header(info, isbreakable: true) = {
  cvheading(info, settings)
}

#let layout_timeline(data, primary_element: none, secondary_element: none, tertiary_element: none, settings: none, isbreakable: true) = {
  // Get the global settings
  let year_column_width = 7em
  
  // Get spacing settings with defaults
  let entry_spacing = settings.at("entry_spacing", default: 0.5em)
  let element_spacing = -1em + settings.at("element_spacing", default: 2pt) // Space between primary/secondary/tertiary
  
  // Convert single elements to arrays for consistent handling
  let primary = if type(primary_element) == array { primary_element } else { (primary_element,) }
  let secondary = if type(secondary_element) == array { secondary_element } else { (secondary_element,) }
  let tertiary = if type(tertiary_element) == array { tertiary_element } else { (tertiary_element,) }
  
  // List of mentor types for special handling
  let mentor_types = (
    (key: "advisors", singular: "Advisor", plural: "Advisors"),
    (key: "professors", singular: "Professor", plural: "Professors"),
    (key: "supervisors", singular: "Supervisor", plural: "Supervisors")
  )
  
 // Helper function to check if a field is a mentor type
  let is_mentor_type(field) = {
    for type in mentor_types {
      if field == type.key {
        return true
      }
    }
    return false
  }
  
  // Helper function to format mentor lists
  let format_mentors(entry, key) = {
    let mentor_type = mentor_types.find(t => t.key == key)
    if mentor_type == none { return none }
    
    let mentors = entry.at(key, default: none)
    if mentors == none or mentors.len() == 0 { return none }
    
    // Create the label part in italic
    let label = if mentors.len() == 1 { mentor_type.singular + ":" } else { mentor_type.plural + ":" }
    
    // Format the mentor names
    let names = if mentors.len() == 1 {
      mentors.at(0)
    } else if mentors.len() == 2 {
      [#mentors.at(0) and #mentors.at(1)]
    } else {
      let result = []
      for (i, mentor) in mentors.enumerate() {
        if i == mentors.len() - 1 {
          result = result + [and #mentor]
        } else if i == mentors.len() - 2 {
          result = result + [#mentor ]
        } else {
          result = result + [#mentor, ]
        }
      }
      result
    }
    
    // Combine the label and names
    [#text(style: "italic")[#label] #names]
  }
  
  // Create the container block
  block(width: 100%, breakable: isbreakable, inset: 0pt, outset: 0pt)[
    // Process each entry
    #for (i, entry) in data.enumerate() {
      // Format year text
      let year_text = if "end_date" in entry and entry.end_date != none {
        if "start_date" in entry and entry.start_date != none {
          if entry.end_date == "present" or entry.end_date == "Present" {
            [#entry.start_date - Present]
          } else if entry.start_date == entry.end_date {
            [#entry.start_date]
          } else {
            [#entry.start_date - #entry.end_date]
          }
        } else {
          [#entry.end_date]
        }
      } else if "start_date" in entry and entry.start_date != none {
        [#entry.start_date]
      } else {
        []
      }
      
      // Create grid for this entry
      grid(
        columns: (year_column_width, 1fr),
        gutter: 1em,
        
        // Year column
        align(right)[#year_text],
        
        grid.vline(),
        
        // Entry details with configurable spacing
        pad(left: 0.5em)[
          // PRIMARY ELEMENTS SECTION
          
          // First primary element (bold)
          #let first_primary_found = false
          #let first_primary_field = none
          #let first_primary_content = none
          
          // Find the first available primary element
          #for field in primary {
            if field in entry and entry.at(field) != none and not first_primary_found {
              first_primary_field = field
              first_primary_content = entry.at(field)
              first_primary_found = true
              break
            }
          }
          
          // Display first primary element in bold if found
          #if first_primary_found {
            text(weight: "bold")[#first_primary_content]
            
            // Handle location specially for institution
            if first_primary_field == "institution" and "location" in entry and entry.location != none {
              [, #entry.location]
            }
            
            // Check for other primary elements to display in normal weight
            let additional_primary = ()
            for field in primary {
              if field != first_primary_field and field in entry and entry.at(field) != none {
                additional_primary.push(entry.at(field))
              }
            }
            
            // Add additional primary elements if any
            if additional_primary.len() > 0 {
              [, #additional_primary.join(", ")]
            }
          }
          
          // SECONDARY ELEMENTS SECTION
          
          // Collect all secondary elements
          #let secondary_content = ()
          
          // Regular secondary elements
          #for field in secondary {
            if not is_mentor_type(field) and field in entry and entry.at(field) != none {
              secondary_content.push(entry.at(field))
            }
          }
          
          // Add mentor fields from secondary
          #for field in secondary {
            if is_mentor_type(field) {
              let mentor_text = format_mentors(entry, field)
              if mentor_text != none {
                secondary_content.push(mentor_text)
              }
            }
          }
          
          // Add mentor types not explicitly in secondary
          #for type in mentor_types {
            if type.key not in secondary and type.key in entry and entry.at(type.key) != none {
              let mentor_text = format_mentors(entry, type.key)
              if mentor_text != none {
                secondary_content.push(mentor_text)
              }
            }
          }
          
          // Display secondary content if exists
          #if secondary_content.len() > 0 and first_primary_found {
            v(element_spacing) // Add spacing between primary and secondary
            
            // We need to handle secondary content differently
            // For regular secondary elements (not advisor/professor), use italic
            // For advisor/professor elements, they are already formatted correctly
            let regular_secondary = ()
            let special_secondary = ()
            
            for item in secondary_content {
              if type(item) == str {
                regular_secondary.push(item)
              } else {
                special_secondary.push(item)
              }
            }
            
            // Display regular secondary elements in italic if any exist
            if regular_secondary.len() > 0 {
              text(style: "italic")[#regular_secondary.join(", ")]
            }
            
            // Display special secondary elements (already formatted) if any exist
            if special_secondary.len() > 0 {
              if regular_secondary.len() > 0 { [, ] }
              special_secondary.join(", ")
            }
          }
          
          // TERTIARY ELEMENTS SECTION
          
          // Collect tertiary elements
          #let tertiary_content = ()
          #for field in tertiary {
            if field in entry and entry.at(field) != none {
              tertiary_content.push(entry.at(field))
            }
          }
          
          // Display tertiary content if exists
          #if tertiary_content.len() > 0 {
            if first_primary_found or secondary_content.len() > 0 {
              v(element_spacing) // Add spacing before tertiary
            }
            
            text(size: 8pt)[
              #tertiary_content.join(", ")
            ]
          }
        ]
      )
      
      // Add configurable space between entries
      if i < data.len() - 1 {
        v(entry_spacing)
      }
    }
  ]
}

#let layout_numbered_list(data, isbreakable: true) = {
  // Set width for the number column
  let number_width = 2em
  
  block(width: 100%, breakable: isbreakable)[
    // Check if data is an array (direct list of citations)
    #if type(data) == array {
      for (index, citation) in data.enumerate() {
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
        if index < data.len() - 1 {
          v(0.05em)
        }
      }
    } else {
      [No entries found]
    }
  ]
}

#let layout_prose(data, isbreakable: true) = {
  block(width: 100%, breakable: isbreakable)[
    #if type(data) == str {
      [#data]
    } else if type(data) == array {
      for item in data {
        [#item]
        if item != data.last() { linebreak() }
      }
    } else {
      [No valid prose content found]
    }
  ]
}

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


// Main section rendering function
#let cvsection(info, layout: none, section: none, title: none, settings: none, isbreakable: true) = {
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
                } else if layout == "timeline" {
                    // Get the primary, secondary, tertiary elements from the section if they exist
                    let primary = if "primary_element" in info { info.primary_element } else { "none" }
                    let secondary = if "secondary_element" in info { info.secondary_element } else { "none" }
                    let tertiary = if "tertiary_element" in info { info.tertiary_element } else { "none" }
                    
                    layout_timeline(info.at(section_key), 
                                   primary_element: primary, 
                                   secondary_element: secondary, 
                                   tertiary_element: tertiary, 
                                   settings: settings,
                                   isbreakable: isbreakable)
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