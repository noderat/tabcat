###
Copyright (c) 2015, Regents of the University of California
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

  1. Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.
  2. Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###

# default fallback language, for i18n
DEFAULT_FALLBACK_LNG = 'en'

Translations = {}

if module?  # inside CouchDB
  module.exports = Translations = {}
else  # inside browser
  @TabCAT ?= {}
  @TabCAT.Translations = Translations

Translations.translations =
  en:
    translation:
      return_to_examiner:
        'Please return to the examiner'
      i_am_the_examiner:
        'I am the examiner'
      task_complete:
        'Task complete!'
      button:
        back: 'Back'
        next: 'Next'
        begin: 'Begin'
        complete: 'Complete'
  es:
    translation:
      return_to_examiner:
        'Por favor devuelva la tableta al examinador'
      i_am_the_examiner:
        'Soy el examinador'
      task_complete:
        'Tarea terminada!'
      button:
        back: 'Retroceder'
        next: 'Siguiente'
        begin: 'Empiezar'
        complete: 'Ha finalizado'

Translations.init = (options) ->
# set up i18n
  defaultOptions = {
    fallbackLng: DEFAULT_FALLBACK_LNG
    useCookie: false,
    resStore: { translation: {}}
  }

  if window.localStorage.currentLanguage?
    defaultOptions.lng = window.localStorage.currentLanguage

  i18n_options = _.extend( defaultOptions, options)

  #merge translation keys
  for language, translation of TabCAT.Translations.translations
    do ->
      if not i18n_options.resStore[language]?
        i18n_options.resStore[language] = {}
      i18n_options.resStore[language].translation = _.extend(
        translation.translation,
        i18n_options.resStore[language].translation
      )
  $.i18n.init(i18n_options)
  #apply the translations to all of the data-i18n tags on the page
  $("body").i18n()