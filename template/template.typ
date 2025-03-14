// #import "@preview/imprecv:1.0.1": *

// Or for local development
#import "../cv.typ": *

// Import your CV data
#let cv_data = yaml("template.yml")

// Validate that required fields exist in each section
#for section in cv_data.sections {
  if "key" not in section {
    panic("Missing 'key' in section: " + str(section))
  }
  if "layout" not in section {
    panic("Missing 'layout' in section with key: " + section.key)
  }
  if "title" not in section and section.key != "personal" {
    warn("Missing 'title' in section with key: " + section.key)
  }
}

// Get settings from YAML file
#let settings = cv_data.settings

// Define default settings if not present in YAML
#let default_settings = (
    headingfont: "Libertinus Serif",
    bodyfont: "Libertinus Serif",
    fontsize: 10pt,
    linespacing: 6pt,
    sectionspacing: 12pt,
    showAddress: true,
    showNumber: false,
    showTitle: false,
    headingsmallcaps: false,
    sendnote: false,
)

// Merge with defaults for any missing settings
#let convert_string_to_length(string) = {
  if type(string) == str {
    if string.ends-with("pt") {
      return float(string.replace("pt", "")) * 1pt
    } else if string.ends-with("em") {
      return float(string.replace("em", "")) * 1em
    } else if string.ends-with("cm") {
      return float(string.replace("cm", "")) * 1cm
    } else if string.ends-with("mm") {
      return float(string.replace("mm", "")) * 1mm
    } else {
      return string
    }
  } else {
    return string
  }
}

#let convert_string_to_color(string_value) = {
  if type(string_value) == str {
    if string_value.starts-with("rgb(") and string_value.ends-with(")") {
      let rgb_str = string_value.slice(4, string_value.len() - 1)
      let components = rgb_str.split(",").map(s => int(float(s.trim())))
      if components.len() == 3 {
        return rgb(components.at(0), components.at(1), components.at(2))
      }
    } else if string_value.starts-with("rgba(") and string_value.ends-with(")") {
      let rgba_str = string_value.slice(5, string_value.len() - 1)
      let components = rgba_str.split(",")
      if components.len() == 4 {
        let r = int(float(components.at(0).trim()))
        let g = int(float(components.at(1).trim()))
        let b = int(float(components.at(2).trim()))
        let a = float(components.at(3).trim())
        return rgba(r, g, b, a)
      }
    } else if string_value.starts-with("#") {
      // Convert hex color to rgb
      let hex = string_value.slice(1)
      if hex.len() == 6 {
        let r = int(hex.slice(0, 2), base: 16)
        let g = int(hex.slice(2, 4), base: 16)
        let b = int(hex.slice(4, 6), base: 16)
        return rgb(r, g, b)
      } else if hex.len() == 3 {
        let r = int(hex.at(0) + hex.at(0), base: 16)
        let g = int(hex.at(1) + hex.at(1), base: 16)
        let b = int(hex.at(2) + hex.at(2), base: 16)
        return rgb(r, g, b)
      }
    }
  }
  
  // Default to blue if conversion fails
  return rgb(0, 0, 255)  // Using integer values now
}

#let settings = if settings != none {
  // First add any missing settings from defaults
  for (k, v) in default_settings {
    if k not in settings {
      settings.insert(k, v)
    }
  }
  
  // Convert length strings to actual length values
  if "fontsize" in settings {
    settings.fontsize = convert_string_to_length(settings.fontsize)
  }
  if "linespacing" in settings {
    settings.linespacing = convert_string_to_length(settings.linespacing)
  }
  if "sectionspacing" in settings {
    settings.sectionspacing = convert_string_to_length(settings.sectionspacing)
  }
  if "entry_spacing" in settings {
    settings.entry_spacing = convert_string_to_length(settings.entry_spacing)
  }
  if "element_spacing" in settings {
    settings.element_spacing = convert_string_to_length(settings.element_spacing)
  }
  if "page" in settings and "margin" in settings.page {
    settings.page.margin = convert_string_to_length(settings.page.margin)
  }
  
  // Convert color strings to color values
  if "hyperlink_color" in settings {
    settings.hyperlink_color = convert_string_to_color(settings.hyperlink_color)
  }
  
  settings
} else {
  default_settings
}

#let customrules(doc) = {
    // Get page settings from YAML if available
    set page(                 // https://typst.app/docs/reference/layout/page
        paper: if "page" in settings and "paper" in settings.page { 
          settings.page.paper 
        } else { 
          "a4" 
        },
        numbering: if "page" in settings and "numbering" in settings.page { 
          settings.page.numbering 
        } else { 
          "1 / 1" 
        },
        number-align: if "page" in settings and "number-align" in settings.page { 
          // Convert string align values to actual Typst align values
          let align = settings.page.number-align
          if align == "center" { center } 
          else if align == "left" { left } 
          else if align == "right" { right }
          else { center }  // Default
        } else { 
          center 
        },
        margin: if "page" in settings and "margin" in settings.page { 
          settings.page.margin 
        } else { 
          3.5cm 
        },
    )
    
    // Set hyperlink styling
    show link: it => {
        text(
            fill: if "hyperlink_color" in settings { 
              settings.hyperlink_color 
            } else { 
              rgb(0, 0, 255) // Default blue
            },
        )[#it]
    }
    
    // set list(indent: 1em)
    doc
}

#let cvinit(doc) = {
    doc = setrules(settings, doc)
    doc = showrules(settings, doc)
    doc = customrules(doc)
    doc
}

// Function to create data for a section that uses the new structure
#let get_section_data(section, cv_data) = {
  // Create a dictionary that will hold all relevant section data
  let result = (:)
  
  // First check if this section has entries in it
  if "entries" in section {
    // Add entries to result
    result.insert("entries", section.entries)
  } else {
    // If the section doesn't have entries, use the existing top-level data
    if section.key in cv_data {
      result.insert("entries", cv_data.at(section.key))
    } else {
      // Set empty array if data is not found
      result.insert("entries", [])
    }
  }
  
  // Add layout configuration if present
  if "primary_element" in section {
    result.insert("primary_element", section.primary_element)
  }
  if "secondary_element" in section {
    result.insert("secondary_element", section.secondary_element)
  }
  if "tertiary_element" in section {
    result.insert("tertiary_element", section.tertiary_element)
  }
  
  return result
}

#show: doc => cvinit(doc)

// Process CV sections dynamically based on the YAML configuration
#if "sections" in cv_data {
  for section in cv_data.sections {
    if section.at("show", default: true) == true {
      if section.key == "personal" {
        // Special case for personal/heading section
        cvheading(cv_data, settings)
      } else {
        // Standard sections
        let layout = section.layout
        let key = section.key
        let title = section.title
        
        // Get the data for this section
        let section_data = get_section_data(section, cv_data)
        
        // Create a temporary dictionary with just this section's data
        let temp_data = (
          personal: cv_data.personal,  // Keep personal for reference
          (key): section_data.entries,  // Add this section's entries
        )
        
        // Add layout configuration if present
        if "primary_element" in section_data {
          temp_data.insert("primary_element", section_data.primary_element)
        }
        if "secondary_element" in section_data {
          temp_data.insert("secondary_element", section_data.secondary_element)
        }
        if "tertiary_element" in section_data {
          temp_data.insert("tertiary_element", section_data.tertiary_element)
        }
        
        // Call cvsection with the appropriate data
        cvsection(temp_data, layout: layout, section: key, settings: settings, title: title)
      }
    }
  }
}