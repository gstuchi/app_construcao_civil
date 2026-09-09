'use strict';
function hojeNoFuso(tz, agora = new Date()){
  try{ return new Intl.DateTimeFormat('en-CA', { timeZone:tz || 'America/Sao_Paulo' }).format(agora); }
  catch{ return new Intl.DateTimeFormat('en-CA', { timeZone:'America/Sao_Paulo' }).format(agora); }
}
module.exports = { hojeNoFuso };
