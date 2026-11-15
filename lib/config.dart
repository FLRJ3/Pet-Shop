class Config {
  // false = modo demonstração (dados de exemplo, não precisa de servidor)
  // true  = usa a API do sistema Java, que acessa o banco MySQL
  static const bool usarApi = false;

  // Endereço da API do sistema Java (Tomcat)
  static const String urlApi = 'http://localhost:8080/petshop/api';
}
