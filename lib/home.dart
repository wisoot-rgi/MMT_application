import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset(
      'assets/videos/BGC_final_web.mp4',
    )
      ..initialize().then((_) {
        setState(() {});
      })
      ..setLooping(true)
      ..setVolume(0)
      ..play();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // ================= VIDEO HEADER =================
        _controller.value.isInitialized
            ? GestureDetector(
                onTap: () {
                  setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  });
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                    if (!_controller.value.isPlaying)
                      const Icon(
                        Icons.play_circle_fill,
                        size: 60,
                        color: Colors.white,
                      ),
                  ],
                ),
              )
            : const SizedBox(
                height: 250,
                child: Center(child: CircularProgressIndicator()),
              ),

        // ================= CONTENT =================
        titleSection,
        const SizedBox(height: 10),
        buttonSection,
        textSection,

        // ================= 🔥 IMAGE (NEW) =================
        const SizedBox(height: 20),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/glass_packaging.png',
              fit: BoxFit.cover,
            ),
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}

//====================================================================
Widget titleSection = Container(
  padding: const EdgeInsets.all(20),
  child: Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BG container glass PCL',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              '5 plants, Thailand',
              style: TextStyle(color: Colors.grey.shade600),
            )
          ],
        ),
      ),
      Icon(Icons.star, color: Colors.red.shade400),
      const SizedBox(width: 4),
      const Text('50'),
    ],
  ),
);

//======================================================================
Widget buttonSection = Padding(
  padding: const EdgeInsets.symmetric(vertical: 10),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      _buildButtonColumn(Colors.blueGrey, Icons.call, 'Call'),
      _buildButtonColumn(Colors.blueGrey, Icons.near_me, 'Route'),
      _buildButtonColumn(Colors.blueGrey, Icons.share, 'Share'),
    ],
  ),
);

Column _buildButtonColumn(Color color, IconData icon, String label) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: color),
      const SizedBox(height: 6),
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    ],
  );
}

//======================================================================
Widget textSection = Container(
  padding: const EdgeInsets.all(20),
  child: const Text(
    '  Incorporated in 1974, Bangkok Glass, granted promotional privileges by '
    'the Office of the Board of Investment (BOI), was registered with a capital '
    'of 50 million (THB). The first glass-bottling plant was completed in the '
    'district of Thanyaburi in Pathumthani province with capability of '
    'producing as much as 150 tons per day. Since Boon Rawd Brewery Co.Ltd. '
    'has become the major shareholder of the company in 1983, '
    'Bangkok Glass has been able to expand continuously its production '
    'capacity and becomes the biggest in production capacity in Thailand.',
    softWrap: true,
    style: TextStyle(height: 1.5),
  ),
);