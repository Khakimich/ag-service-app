import 'package:mobile/core/nav.dart'; // AG_FIX3
import 'package:flutter/material.dart';
import '../../../core/i18n.dart'; // AG_I18N1

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  static const _orange = Color(0xFFFF6A00);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(leading: const AgBackButton(fallback: '/profile'), /* AG_FIX3 */ 
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          tr('Документы'),
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6A00), Color(0xFFFF8A3D)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: 54,
                    height: 54,
                    child: Icon(
                      Icons.description_rounded,
                      color: _orange,
                      size: 28,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('Документы AG Service'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        tr('Правовая информация и условия использования сервиса'),
                        style: TextStyle(color: Colors.white, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _SectionTitle(tr('Персональные данные')),

          _DocumentTile(
            icon: Icons.shield_outlined,
            title: tr('Политика обработки персональных данных'),
            subtitle: tr('Какие данные мы обрабатываем и для чего'),
            onTap:
                () => _openDocument(
                  context,
                  title: tr('Политика обработки персональных данных'),
                  text: _privacyPolicy,
                ),
          ),

          _DocumentTile(
            icon: Icons.fact_check_outlined,
            title: tr('Согласие на обработку персональных данных'),
            subtitle: tr('Условия предоставления и обработки данных'),
            onTap:
                () => _openDocument(
                  context,
                  title: tr('Согласие на обработку персональных данных'),
                  text: _personalDataConsent,
                ),
          ),

          const SizedBox(height: 22),

          _SectionTitle(tr('Использование приложения')),

          _DocumentTile(
            icon: Icons.article_outlined,
            title: tr('Пользовательское соглашение'),
            subtitle: tr('Правила использования AG Service'),
            onTap:
                () => _openDocument(
                  context,
                  title: tr('Пользовательское соглашение'),
                  text: _userAgreement,
                ),
          ),

          _DocumentTile(
            icon: Icons.lock_outline_rounded,
            title: tr('Политика конфиденциальности'),
            subtitle: tr('Защита информации пользователя'),
            onTap:
                () => _openDocument(
                  context,
                  title: tr('Политика конфиденциальности'),
                  text: _confidentiality,
                ),
          ),

          const SizedBox(height: 22),

          _SectionTitle(tr('Уведомления')),

          _DocumentTile(
            icon: Icons.notifications_none_rounded,
            title: tr('Согласие на рекламные сообщения'),
            subtitle: tr('Акции, предложения и новости сервиса'),
            onTap:
                () => _openDocument(
                  context,
                  title: tr('Согласие на рекламные сообщения'),
                  text: _advertisingConsent,
                ),
          ),

          const SizedBox(height: 22),

          _SectionTitle(tr('Организация')),

          _DocumentTile(
            icon: Icons.business_outlined,
            title: tr('Реквизиты и контакты'),
            subtitle: tr('Информация об операторе сервиса'),
            onTap:
                () => _openDocument(
                  context,
                  title: tr('Реквизиты и контакты'),
                  text: _companyDetails,
                ),
          ),

          const SizedBox(height: 26),

          Center(
            child: Text(
              tr('AG Service • Документы'),
              style: TextStyle(
                color: Color(0xFF9A9A9A),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _openDocument(
    BuildContext context, {
    required String title,
    required String text,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _DocumentView(title: title, text: text),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1E8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: const Color(0xFFFF6A00)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DocumentView extends StatelessWidget {
  const _DocumentView({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(leading: const AgBackButton(fallback: '/profile'), /* AG_FIX3 */ 
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        title: Text(
          title,
          maxLines: 2,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AG SERVICE',
                style: TextStyle(
                  color: Color(0xFFFF6A00),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr('Редакция от 02 октября 2026 года'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.65,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const String _privacyPolicy = '''
1. ОБЩИЕ ПОЛОЖЕНИЯ

Настоящая Политика определяет порядок обработки и защиты персональных данных пользователей приложения AG Service.

Оператор использует персональные данные только для определённых и законных целей, связанных с работой приложения, записью на обслуживание автомобиля, взаимодействием с клиентом и оказанием услуг.

2. КАКИЕ ДАННЫЕ МОГУТ ОБРАБАТЫВАТЬСЯ

В зависимости от используемых функций приложение может обрабатывать:
• имя и фамилию;
• номер телефона;
• сведения об автомобиле;
• марку и модель автомобиля;
• государственный регистрационный номер;
• VIN автомобиля;
• историю записей на обслуживание;
• выбранные услуги;
• дату и время записи;
• сведения, предоставленные пользователем в обращениях;
• технические данные, необходимые для работы и безопасности приложения.

3. ЦЕЛИ ОБРАБОТКИ

Данные могут использоваться для:
• регистрации и идентификации пользователя;
• создания и управления записью в автосервис;
• ведения истории обслуживания;
• связи с клиентом по вопросам записи;
• предоставления информации о статусе записи;
• улучшения работы приложения;
• обеспечения безопасности сервиса;
• исполнения требований законодательства.

4. ДЕЙСТВИЯ С ДАННЫМИ

Оператор может осуществлять сбор, запись, систематизацию, накопление, хранение, уточнение, извлечение, использование, передачу в предусмотренных законом и необходимых для оказания услуги случаях, блокирование и удаление персональных данных.

5. ХРАНЕНИЕ И ЗАЩИТА

Оператор принимает организационные и технические меры для защиты персональных данных от неправомерного доступа, изменения, раскрытия, уничтожения и иных неправомерных действий.

Персональные данные хранятся не дольше, чем этого требуют цели их обработки или требования законодательства.

6. ПРАВА ПОЛЬЗОВАТЕЛЯ

Пользователь вправе запрашивать сведения об обработке своих персональных данных, требовать их уточнения, блокирования или удаления в случаях, предусмотренных законодательством.

Пользователь также вправе отозвать ранее предоставленное согласие, если обработка осуществляется на основании такого согласия.

7. ИЗМЕНЕНИЕ ПОЛИТИКИ

Политика может обновляться при изменении функций AG Service или требований законодательства. Актуальная редакция размещается в приложении.

8. ОПЕРАТОР

Оператор: ИП Охунджанов Мухаммаджон Кудратович
ИНН: 667906235552
ОГРНИП: 320665800119462
Адрес: г. Екатеринбург, ул. Чемпионов, 13А
Контакт для вопросов по персональным данным: app@autogrom.ru, +7 999 566 1001
''';

const String _personalDataConsent = '''
Я свободно, своей волей и в своём интересе предоставляю оператору AG Service согласие на обработку предоставленных мной персональных данных.

Цель обработки: регистрация и работа в приложении AG Service, запись на обслуживание автомобиля, управление записями, связь со мной по вопросам оказания услуг и исполнение связанных с этим обязательств.

Перечень данных может включать имя, фамилию, номер телефона, сведения об автомобиле, государственный регистрационный номер, VIN, выбранные услуги, сведения о записи и иную информацию, которую я самостоятельно предоставляю через приложение.

Я разрешаю совершать с указанными данными действия, необходимые для достижения перечисленных целей, включая сбор, запись, систематизацию, накопление, хранение, уточнение, извлечение, использование, блокирование и удаление.

Согласие действует в течение срока, необходимого для достижения целей обработки, либо до его отзыва, если законодательством или иным законным основанием не предусмотрено продолжение обработки.

Я понимаю, что вправе отозвать согласие путём направления обращения оператору.

Оператор:
ИП Охунджанов Мухаммаджон Кудратович
ИНН: 667906235552
Адрес: г. Екатеринбург, ул. Чемпионов, 13А
Контакт: app@autogrom.ru, +7 999 566 1001
''';

const String _userAgreement = '''
1. ОБЩИЕ УСЛОВИЯ

AG Service предоставляет пользователю возможность просматривать услуги автосервиса, выбирать специалиста, дату и время, добавлять автомобиль и создавать запись на обслуживание.

Используя приложение, пользователь обязуется предоставлять достоверные сведения, необходимые для работы выбранных функций.

2. ОНЛАЙН-ЗАПИСЬ

Создание записи через приложение означает направление заявки на оказание выбранной услуги.

Фактический объём работ, окончательная стоимость и сроки могут уточняться после диагностики автомобиля и согласования с клиентом.

3. АВТОМОБИЛЬ

Пользователь самостоятельно отвечает за корректность введённых сведений об автомобиле, включая марку, модель, государственный номер и VIN.

4. СТОИМОСТЬ

Информация о стоимости в приложении может носить предварительный характер, если окончательная цена зависит от состояния автомобиля, необходимых работ, запчастей или результатов диагностики.

5. ОТМЕНА И ИЗМЕНЕНИЕ ЗАПИСИ

Пользователь может обратиться в сервис для изменения или отмены записи. Возможности управления записью также могут предоставляться непосредственно в приложении.

6. РАБОТА ПРИЛОЖЕНИЯ

Отдельные функции приложения могут временно быть недоступны из-за технического обслуживания, обновлений или обстоятельств, не зависящих от оператора.

7. ИЗМЕНЕНИЯ

Актуальная редакция настоящего соглашения публикуется в приложении AG Service.
''';

const String _confidentiality = '''
AG Service стремится обеспечивать конфиденциальность информации пользователя.

Доступ к персональным данным предоставляется только в объёме, необходимом для работы сервиса, обслуживания клиента, выполнения обязанностей оператора и обеспечения безопасности.

Оператор не раскрывает персональные данные неопределённому кругу лиц без законного основания.

Для защиты информации могут применяться технические и организационные меры, включая разграничение доступа, авторизацию, контроль доступа к информационным системам и иные необходимые меры.

Передача данных организациям, участвующим в техническом обеспечении или оказании заказанной пользователем услуги, допускается только при наличии соответствующего правового основания и в необходимом объёме.

Пользователь должен самостоятельно обеспечивать сохранность доступа к своему устройству и не передавать третьим лицам коды подтверждения и иные средства авторизации.
''';

const String _advertisingConsent = '''
Настоящее согласие является отдельным от согласия на обработку персональных данных для основной работы приложения.

Пользователь может добровольно согласиться на получение информации об акциях, специальных предложениях, новых услугах и других рекламных материалах AG Service.

Сообщения могут направляться только по каналам, для которых получено необходимое согласие пользователя, например посредством push-уведомлений, SMS или иных средств связи.

Отказ от рекламных сообщений не должен препятствовать использованию основных функций приложения и получению сообщений, необходимых для исполнения записи или оказания заказанной услуги.

Пользователь вправе отказаться от рекламных сообщений и отозвать соответствующее согласие.
''';

String get _companyDetails => tr('\nAG SERVICE\n\nАдрес автосервиса:\nг. Екатеринбург, ул. Чемпионов, 13А\n\nОператор:\nИП Охунджанов Мухаммаджон Кудратович\n\nИНН:\n667906235552\n\nОГРНИП:\n320665800119462\n\nАдрес:\nг. Екатеринбург, ул. Чемпионов, 13А\n\nТелефон:\n+7 999 566 1001\n\nЭлектронная почта:\napp@autogrom.ru\n\nКонтакт по вопросам персональных данных:\napp@autogrom.ru\n');
