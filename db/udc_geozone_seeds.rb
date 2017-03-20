# encoding: UTF-8
# Use Centros as Geozones. Extacted from: http://www.udc.es/centros_departamentos_servizos/centros

coruna = ["Escola Técnica Superior de Arquitectura",
  "Escola Técnica Superior de Enxeñeiros de Camiños, Canais e Portos",
  "Escola Técnica Superior de Náutica e Máquinas",
  "Escola Universitaria de Arquitectura Técnica",
  "Facultade de Ciencias",
  "Facultade de Ciencias da Comunicación",
  "Facultade de Ciencias da Educación",
  "Facultade de Ciencias da Saúde",
  "Facultade de Ciencias do Deporte e a Educación Física",
  "Facultade de Dereito",
  "Facultade de Economía e Empresa",
  "Facultade de Filoloxía",
  "Facultade de Fisioterapia",
  "Facultade de Informática",
  "Facultade de Socioloxía"]

ferrol = ["Escola Politécnica Superior",
  "Escola Universitaria de Deseño Industrial",
  "Escola Universitaria Politécnica",
  "Facultade de Ciencias do Traballo",
  "Facultade de Enfermaría e Podoloxía",
  "Facultade de Humanidades e Documentación"]

adscritos = ["Escola Universitaria de Enfermaría",
  "Escola Universitaria de Relacións Laborais",
  "Escola Universitaria de Turismo"]

Geozone.delete_all

(coruna | ferrol | adscritos).map do |centro|
  Geozone.create(name: centro)
end
