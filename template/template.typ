// #import "@preview/imprecv:1.0.1": *

// Or for local development
#import "../cv.typ": *

// Import your CV data
#let cv_data = yaml("template.yml")

// Define user variables
#let settings = (
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

// setrules and showrules can be overridden by re-declaring it here
// #let setrules(doc) = {
//      // add custom document style rules here
//
//      doc
// }

#let customrules(doc) = {
    // add custom document style rules here
    set page(                 // https://typst.app/docs/reference/layout/page
        paper: "a4",
        numbering: "1 / 1",
        number-align: center,
        margin: 3.5cm,
    )
    // set list(indent: 1em)
    doc
}

#let cvinit(doc) = {
    doc = setrules(settings, doc)
    doc = showrules(settings, doc)
    doc = customrules(doc)
    doc
}

#show: doc => cvinit(doc)

// CV content structure using appropriate layouts for each section
#cvheading(cv_data, settings)
// #cvsection(cv_data, layout: "paragraph", section: "research", title: "Research")
#cvsection(cv_data, layout: "education", section: "education", title: "Education")
#cvsection(cv_data, layout: "education", section: "experience", title: "Experience")
// #cvsection(cv_data, layout: "experience", title: "Experience")
#cvsection(cv_data, layout: "publications", section: "publications", title: "Publications")
#cvsection(cv_data, layout: "presentations", title: "Presentations")
#cvsection(cv_data, layout: "teaching", section: "teaching", title: "Teaching")
#cvsection(cv_data, layout: "teaching", section: "awards", title: "Scholarships & Awards")
#cvsection(cv_data, layout: "simplelist", section: "service", title: "Service & Mentorship")

// Add the endnote
// #endnote(settings)