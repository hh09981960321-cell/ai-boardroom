import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const GeminiBoardroomApp());
}

class GeminiBoardroomApp extends StatelessWidget {
  const GeminiBoardroomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'شورای هوش مصنوعی جمینای',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A73E8),
          primary: const Color(0xFF1A73E8),
          surface: Colors.white,
        ),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: BoardroomScreen(),
      ),
    );
  }
}

class Agent {
  final String id;
  String name;
  final String role;
  final String icon;
  final Color themeColor;
  final String systemPrompt;
  bool isThinking;

  Agent({
    required this.id,
    required this.name,
    required this.role,
    required this.icon,
    required this.themeColor,
    required this.systemPrompt,
    this.isThinking = false,
  });
}

class BoardroomMessage {
  final String senderName;
  final String senderRole;
  final String icon;
  final Color themeColor;
  final String content;
  final DateTime timestamp;
  final bool isUser;

  BoardroomMessage({
    required this.senderName,
    required this.senderRole,
    required this.icon,
    required this.themeColor,
    required this.content,
    required this.timestamp,
    this.isUser = false,
  });
}

class BoardroomScreen extends StatefulWidget {
  const BoardroomScreen({super.key});

  @override
  State<BoardroomScreen> createState() => _BoardroomScreenState();
}

class _BoardroomScreenState extends State<BoardroomScreen> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _geminiApiKey = '';
  bool _isRunning = false;

  final List<BoardroomMessage> _messages = [];

  late final List<Agent> _agents = [
    Agent(
      id: 'manager',
      name: 'آرش (مدیر کل)',
      role: 'هماهنگ‌کننده و مدیر شورا',
      icon: '👔',
      themeColor: const Color(0xFF1A73E8),
      systemPrompt: 'تو مدیر ارشد یک شورای تخصصی هوش مصنوعی هستی. رئیس (کاربر) دستوری داده است. دستور را به بخش‌های دقیق تفکیک کن، اولویت‌ها را مشخص کن و به هر یک از اعضای شورا (محقق، معمار فنی، ایده‌پرداز، منتقد و کنترل کیفیت) ماموریت مشخصی بسپار. بسیار محترمانه، ساختاریافته و به زبان فارسی پاسخ بده.',
    ),
    Agent(
      id: 'researcher',
      name: 'رها (تحلیل‌گر)',
      role: 'تحلیل‌گر داده و پیش‌نیازها',
      icon: '🔬',
      themeColor: const Color(0xFF0097A7),
      systemPrompt: 'تو محقق ارشد شورا هستی. با توجه به دستور رئیس و تحلیل مدیر، آمارها، استانداردها، الزامات اولیه و فکت‌های مهم این موضوع را استخراج و بیان کن.',
    ),
    Agent(
      id: 'architect',
      name: 'کاوه (معمار فنی)',
      role: 'طراح استراتژی و ساختار اجرایی',
      icon: '📐',
      themeColor: const Color(0xFF2E7D32),
      systemPrompt: 'تو معمار فنی و طراح استراتژی شورا هستی. نقشه راه و مدل پیاده‌سازی عملیاتی گام‌به‌گام را به صورت کاربردی و دقیق تشریح کن.',
    ),
    Agent(
      id: 'creative',
      name: 'سارا (نوآور)',
      role: 'ایده‌پرداز خلاق و تمایز',
      icon: '✨',
      themeColor: const Color(0xFFE91E63),
      systemPrompt: 'تو مسئول نوآوری و ایجاد تمایز هستی. ایده‌های جذاب، ارزش‌های افزوده و راه‌حل‌های خارج از چارچوب اضافه کن که طرح را متمایز کند.',
    ),
    Agent(
      id: 'critic',
      name: 'مهران (ناظر ریسک)',
      role: 'منتقد و ارزیاب چالش‌ها',
      icon: '⚖️',
      themeColor: const Color(0xFFE65100),
      systemPrompt: 'تو منتقد هوشمند و ناظر ریسک شورا هستی. نقاط ضعف، خطرات، چالش‌های پنهان و باگ‌های احتمالی طرح‌های مطرح‌شده را با دقت نقد کن و راهکار اصلاحی ارائه بده.',
    ),
    Agent(
      id: 'qa',
      name: 'پریا (کنترل کیفیت)',
      role: 'تضمین انطباق با دستور رئیس',
      icon: '🛡️',
      themeColor: const Color(0xFF673AB7),
      systemPrompt: 'تو مسئول کنترل کیفیت هستی. بررسی کن که آیا تمام جزئیات خواسته اولیه رئیس لحاظ شده است؟ چالش‌های منتقد چگونه رفع شده است؟ خروجی را بررسی و تایید کن.',
    ),
    Agent(
      id: 'synthesizer',
      name: 'کیان (دبیر کل)',
      role: 'جمع‌بندی‌کننده و سخنگوی شورا',
      icon: '📋',
      themeColor: const Color(0xFF00897B),
      systemPrompt: 'تو دبیر اجرایی شورا هستی. تمام مباحث ۶ عضو قبلی را با نهایت دقت جمع‌بندی کن و یک خروجی نهایی فوق‌العاده تمیز، شفاف، دسته‌بندی‌شده و آماده اجرا برای رئیس (کاربر) بنویس.',
    ),
  ];

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<String> _callGeminiApi(String systemPrompt, String historyContext) async {
    if (_geminiApiKey.trim().isEmpty) {
      throw Exception('لطفاً ابتدا کلید API جمینای خود را وارد کنید.');
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_geminiApiKey',
    );

    final payload = {
      "contents": [
        {
          "parts": [
            {
              "text": "نقش و دستورالعمل سیستمی تو:\n$systemPrompt\n\nروند جلسه تاکنون:\n$historyContext\n\nوظیفه: اکنون بر اساس نقش مشخص خود به زبان فارسی نظر و خروجی تخصصی خود را بیان کن."
            }
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.7,
        "maxOutputTokens": 1000,
      }
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      if (text != null) return text.toString().trim();
      return 'پاسخی دریافت نشد.';
    } else {
      final err = jsonDecode(response.body);
      final errMsg = err['error']?['message'] ?? response.body;
      throw Exception('خطای جمینای (${response.statusCode}): $errMsg');
    }
  }

  Future<void> _startSession(String command) async {
    if (_geminiApiKey.trim().isEmpty) {
      _showApiKeyDialog(isRequired: true);
      return;
    }

    setState(() {
      _isRunning = true;
      _messages.add(
        BoardroomMessage(
          senderName: 'دستور رئیس (شما)',
          senderRole: 'فرماندهی شورا',
          icon: '👑',
          themeColor: const Color(0xFF1A73E8),
          content: command,
          timestamp: DateTime.now(),
          isUser: true,
        ),
      );
    });
    _scrollToBottom();

    String meetingHistory = 'دستور رئیس: "$command"\n\n';

    for (var agent in _agents) {
      if (!mounted) break;

      setState(() {
        agent.isThinking = true;
      });

      try {
        final reply = await _callGeminiApi(agent.systemPrompt, meetingHistory);

        if (!mounted) break;

        setState(() {
          agent.isThinking = false;
          _messages.add(
            BoardroomMessage(
              senderName: agent.name,
              senderRole: agent.role,
              icon: agent.icon,
              themeColor: agent.themeColor,
              content: reply,
              timestamp: DateTime.now(),
            ),
          );
        });

        meetingHistory += '${agent.name} (${agent.role}):\n$reply\n\n';
        _scrollToBottom();
      } catch (e) {
        if (!mounted) break;
        setState(() {
          agent.isThinking = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text('خطا در عملکرد ${agent.name}: $e'),
          ),
        );
        break;
      }
    }

    if (mounted) {
      setState(() {
        _isRunning = false;
      });
    }
  }

  void _showEditAgentsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.people_alt_outlined, color: Color(0xFF1A73E8)),
                  const SizedBox(width: 8),
                  const Text(
                    'شخصی‌سازی نام اعضای شورا',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Text(
                'می‌توانید نام هر کدام از هوش مصنوعی‌ها را به دلخواه خود تغییر دهید:',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _agents.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 8),
                  itemBuilder: (c, index) {
                    final agent = _agents[index];
                    final controller = TextEditingController(text: agent.name);
                    return Row(
                      children: [
                        Text(agent.icon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              labelText: agent.role,
                              labelStyle: const TextStyle(fontSize: 11),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onChanged: (val) {
                              if (val.trim().isNotEmpty) {
                                agent.name = val.trim();
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A73E8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    setState(() {});
                    Navigator.pop(ctx);
                  },
                  child: const Text('ثبت و به‌روزرسانی نام‌ها'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showApiKeyDialog({bool isRequired = false}) {
    final controller = TextEditingController(text: _geminiApiKey);
    showDialog(
      context: context,
      barrierDismissible: !isRequired,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.key, color: Color(0xFF1A73E8)),
            SizedBox(width: 8),
            Text('تنظیم کلید Gemini API', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تنها یک کلید رایگان جمینای برای تمام اعضای شورا کافی است.',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'AIzaSy...',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A73E8),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _geminiApiKey = controller.text.trim();
              });
              Navigator.pop(ctx);
            },
            child: const Text('ذخیره کلید'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4285F4), Color(0xFF9B72CF)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'شورای هوش مصنوعی',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Text(
                  'میزگرد ۷ نفره متصل به Gemini',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'تغییر نام ایجنت‌ها',
            icon: const Icon(Icons.badge_outlined, color: Color(0xFF1A73E8)),
            onPressed: _showEditAgentsModal,
          ),
          IconButton(
            tooltip: 'کلید API',
            icon: Icon(
              Icons.vpn_key_outlined,
              color: _geminiApiKey.isNotEmpty ? const Color(0xFF1A73E8) : Colors.orange,
            ),
            onPressed: () => _showApiKeyDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ردیف افقی اعضای شورا
          Container(
            height: 82,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _agents.length,
              separatorBuilder: (c, i) => const SizedBox(width: 8),
              itemBuilder: (c, index) {
                final agent = _agents[index];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 120,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: agent.isThinking ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: agent.isThinking ? const Color(0xFF1A73E8) : const Color(0xFFE2E8F0),
                      width: agent.isThinking ? 1.6 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(agent.icon, style: const TextStyle(fontSize: 16)),
                          if (agent.isThinking) ...[
                            const SizedBox(width: 4),
                            const SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A73E8)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        agent.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: agent.isThinking ? const Color(0xFF1A73E8) : Colors.black87,
                        ),
                      ),
                      Text(
                        agent.role,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 9, color: Colors.black45),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // جریان گفتگو و خروجی‌ها
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFE8F0FE),
                            ),
                            child: const Icon(Icons.auto_awesome, size: 40, color: Color(0xFF1A73E8)),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'شورای هوش مصنوعی آماده است',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'دستور یا سوال خود را بنویسید؛ اعضای شورا به نوبت با یکدیگر مشورت کرده و نتیجه را تقدیم شما می‌کنند.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12.5, color: Colors.black54, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(14),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, index) {
                      final msg = _messages[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: msg.isUser ? const Color(0xFFF1F5F9) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: msg.isUser ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(msg.icon, style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        msg.senderName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: msg.themeColor,
                                        ),
                                      ),
                                      Text(
                                        msg.senderRole,
                                        style: const TextStyle(fontSize: 10, color: Colors.black45),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.black38),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: msg.content));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('متن کپی شد')),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const Divider(color: Color(0xFFF1F5F9), height: 16),
                            SelectableText(
                              msg.content,
                              style: const TextStyle(
                                fontSize: 13.5,
                                height: 1.6,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // کادر صدور دستور
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _promptController,
                      enabled: !_isRunning,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: _isRunning ? 'شورا در حال گفتگو است...' : 'دستور خود را صادر کنید...',
                        hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFF1A73E8)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: _isRunning ? Colors.grey.shade300 : const Color(0xFF1A73E8),
                    child: IconButton(
                      icon: _isRunning
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.arrow_upward_rounded, color: Colors.white),
                      onPressed: _isRunning
                          ? null
                          : () {
                              final text = _promptController.text.trim();
                              if (text.isNotEmpty) {
                                _promptController.clear();
                                _startSession(text);
                              }
                            },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
