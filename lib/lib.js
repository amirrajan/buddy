window.buddy ||= {}

window.buddy.recommendSelector = function (element) {
  if (element.nodeType == Node.TEXT_NODE) {
    let childElementCount = element.parentNode.childElementCount;
    let childNodeCount = element.parentNode.childNodes.length;
    if (childElementCount == 0 && childNodeCount == 1) {
      return window.buddy.recommendSelector(element.parentNode)
    } else if (element.previousElementSibling) {
      return window.buddy.recommendSelector(element.previousElementSibling)
    }

    return "(no recommendation for text node)"
  }

  if (element.tagName.toLowerCase() == "option") return `${window.buddy.recommendSelector(element.parentNode)}`

  let id = element.attributes["id"]
  let name = element.attributes["name"]
  let dataTest = element.attributes["data-test"]

  if (id) return `#${id.value}`
  if (name) return `[name=${name.value}]`
  if (dataTest) return `[data-test=${dataTest}]`
  return `(no recommedation for <${element.tagName.toLowerCase()}>)`
}

window.buddy.recommendBetterSelector = function (selector, element) {
  if (element.nodeType == Node.TEXT_NODE) {
    return null
  }

  let id = element.attributes["id"]
  let name = element.attributes["name"]
  let dataTest = element.attributes["data-test"]

  if (selector.includes(`#`)) return null
  if (selector.includes(`[name=`)) return null
  if (selector.includes(`[data-test=`)) return null

  if (id && !selector.includes(`#`)) return `#${id.value}`
  if (name && !selector.includes(`[name=`)) return `[name=${name.value}]`
  if (data && !selector.includes(`[data-test=`)) return `[data-test=${dataTest.value}]`
  return null
}

window.buddy.scrollIntoViewIfNeeded = function (element) {
  return;
  const rect = element.getBoundingClientRect()
  let inViewport = (
    rect.top >= 0 &&
      rect.left >= 0 &&
      rect.bottom <= (window.innerHeight || document.documentElement.clientHeight) &&
      rect.right <= (window.innerWidth || document.documentElement.clientWidth)
  )

  if (!inViewport) element.scrollIntoView()
}

// def recommend_selector_js element
//  source = File.read "./recommend-selector.js"
//  element.evaluate source
// end
