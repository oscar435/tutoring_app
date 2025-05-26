import 'package:flutter/material.dart';

class HomePage2 extends StatelessWidget {
  static const routeName = '/home2';
  const HomePage2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: 20),
              _buildSectionTitle('Tutorías agendadas', trailing: 'Todas'),
              _buildHorizontalCards([
                _buildCard(
                  'Mayo 30 - 7:00 pm',
                  Icons.calendar_today,
                  Colors.pinkAccent,
                ),
                _buildCard(
                  'Junio 05 - 5:00 pm',
                  Icons.calendar_today,
                  Colors.lightBlue,
                ),
              ]),
              const SizedBox(height: 20),
              _buildSectionTitle('Nuestros Servicios'),
              Row(
                children: [
                  Expanded(
                    child: _buildServiceCard(
                      'TUTORÍAS',
                      Icons.school,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildServiceCard(
                      'AYUDA PSICOPEDAGÓGICA',
                      Icons.psychology,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSectionTitle(
                'Noticias recientes',
                trailing: 'Todas las noticias',
              ),
              _buildNewsList(),
              const SizedBox(height: 20),
              _buildSectionTitle('Eventos'),
              _buildEventCard('21 Mayo', 'Encuesta estudiantil'),
              const SizedBox(height: 20),
              _buildSectionTitle(
                'Materiales disponibles',
                trailing: 'All Courses',
              ),
              _buildMaterialsRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Icon(Icons.menu),
        Row(
          children: const [
            Icon(Icons.notifications, size: 28),
            SizedBox(width: 10),
            CircleAvatar(
              backgroundImage: AssetImage(
                'assets/avatar.jpg',
              ), // reemplaza con tu imagen
              radius: 18,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, {String? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: const TextStyle(color: Colors.orange, fontSize: 14),
          ),
      ],
    );
  }

  Widget _buildHorizontalCards(List<Widget> cards) {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: cards
            .map(
              (card) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: card,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildCard(String text, IconData icon, Color color) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(String title, IconData icon, Color color) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsList() {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Image.asset('assets/news.png'),
              const Text('FIEI da la bienvenida a sus ingresantes 2025'),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: [
              Image.asset('assets/news2.png'),
              const Text('Villarrealinos presentan muestra escultórica'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(String date, String description) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            date,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildMaterialsRow() {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Image.asset('assets/info_curso.jpg'),
              const Text('Introducción a la Ingeniería Informática'),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: [
              Image.asset('assets/oratoria_curso.jpg'),
              const Text('Dominar la oratoria y el discurso'),
            ],
          ),
        ),
      ],
    );
  }
}
