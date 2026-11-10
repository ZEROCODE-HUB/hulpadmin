import 'dart:math' as math;

import '/auth/supabase_auth/auth_util.dart';
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_web_model.dart';
export 'login_web_model.dart';

class LoginWebWidget extends StatefulWidget {
  const LoginWebWidget({super.key});

  static String routeName = 'LoginWeb';
  static String routePath = '/loginWeb';

  @override
  State<LoginWebWidget> createState() => _LoginWebWidgetState();
}

class _LoginWebWidgetState extends State<LoginWebWidget> {
  static const _desktopBreakpoint = 1050.0;
  static const _marfil = Color(0xFFFBF8F4);
  static const _verdeOscuro = Color(0xFF094E36);
  static const _verdeMarca = Color(0xFF0B6244);
  static const _verdeClaro = Color(0xFFDDF0D9);

  late LoginWebModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LoginWebModel());
    _model.emailTextController ??= TextEditingController();
    _model.textFieldFocusNode1 ??= FocusNode();
    _model.passwordTextController ??= TextEditingController();
    _model.textFieldFocusNode2 ??= FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: _marfil,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: height),
                  child: width >= _desktopBreakpoint
                      ? _buildDesktopLayout(context, width, height)
                      : _buildCompactLayout(context, width),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    double width,
    double viewportHeight,
  ) {
    final headerHeight = (viewportHeight * 0.32).clamp(220.0, 300.0).toDouble();
    final cardWidth = math.min(680.0, width * 0.49);
    final cardRight = width * 0.06;
    final cardTop = headerHeight - 66;
    final layoutHeight = math.max(viewportHeight, cardTop + 560);

    return SizedBox(
      key: const ValueKey('login-desktop-layout'),
      width: width,
      height: layoutHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: headerHeight,
            child: const _LoginHeroBackground(),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: math.min(230.0, layoutHeight * 0.27),
            child: const _LoginBottomWaves(
              key: ValueKey('login-bottom-waves'),
            ),
          ),
          Positioned(
            top: 24,
            left: width * 0.06,
            child: _buildBrandLockup(context),
          ),
          Positioned(
            top: 18,
            right: width * 0.045,
            width: math.min(width * 0.39, 590.0),
            height: headerHeight - 26,
            child: SvgPicture.asset(
              'assets/images/login_services_illustration.svg',
              key: const ValueKey('login-services-illustration'),
              fit: BoxFit.contain,
              alignment: Alignment.centerRight,
            ),
          ),
          Positioned(
            top: headerHeight + 112,
            left: width * 0.06,
            width: width * 0.34,
            child: _buildHeroCopy(context, compact: false),
          ),
          Positioned(
            top: cardTop,
            right: cardRight,
            width: cardWidth,
            child: _buildLoginCard(context, compact: false),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLayout(
    BuildContext context,
    double width,
  ) {
    final headerHeight = width < 420 ? 138.0 : 226.0;
    final horizontalPadding = width < 420 ? 20.0 : 32.0;

    return SizedBox(
      key: const ValueKey('login-compact-layout'),
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: headerHeight,
            child: Stack(
              children: [
                const Positioned.fill(child: _LoginHeroBackground()),
                Positioned(
                  top: 20,
                  left: horizontalPadding,
                  child: _buildBrandLockup(context),
                ),
                if (width >= 420)
                  Positioned(
                    right: 12,
                    bottom: 0,
                    width: math.min(width * 0.42, 310.0),
                    height: headerHeight * 0.66,
                    child: SvgPicture.asset(
                      'assets/images/login_services_illustration.svg',
                      key: const ValueKey('login-services-illustration'),
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomRight,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              width < 420 ? 24 : 36,
              horizontalPadding,
              36,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 660),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeroCopy(context, compact: true),
                    const SizedBox(height: 24),
                    _buildLoginCard(context, compact: true),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandLockup(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final logoWidth = screenWidth >= _desktopBreakpoint
        ? 156.0
        : screenWidth >= 420
            ? 106.0
            : 78.0;
    final logoHeight = screenWidth >= _desktopBreakpoint
        ? 50.0
        : screenWidth >= 420
            ? 36.0
            : 28.0;
    final dividerHeight = screenWidth >= _desktopBreakpoint
        ? 48.0
        : screenWidth >= 420
            ? 34.0
            : 27.0;
    final adminFontSize = screenWidth >= _desktopBreakpoint
        ? 22.0
        : screenWidth >= 420
            ? 16.0
            : 13.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/Union.png',
          key: const ValueKey('login-hulp-logo'),
          width: logoWidth,
          height: logoHeight,
          fit: BoxFit.contain,
        ),
        SizedBox(width: screenWidth >= _desktopBreakpoint ? 24 : 14),
        Container(
          width: 2,
          height: dividerHeight,
          color: _verdeClaro,
        ),
        SizedBox(width: screenWidth >= _desktopBreakpoint ? 24 : 14),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth >= _desktopBreakpoint ? 20 : 13,
            vertical: screenWidth >= _desktopBreakpoint ? 10 : 6,
          ),
          decoration: BoxDecoration(
            color: _verdeClaro,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            'Admin',
            style: theme.labelLarge.copyWith(
              color: _verdeOscuro,
              fontWeight: FontWeight.w700,
              fontSize: adminFontSize,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCopy(BuildContext context, {required bool compact}) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          compact
              ? 'Gestiona los servicios Hulp'
              : 'Gestiona los\nservicios Hulp',
          style: theme.headlineMedium.copyWith(
            color: _verdeOscuro,
            fontSize: compact ? 32 : 48,
            height: 1.12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          compact
              ? 'Acceso seguro para el equipo administrativo.'
              : 'Acceso seguro para el equipo\nadministrativo.',
          style: theme.bodyLarge.copyWith(
            color: theme.secondaryText,
            fontSize: compact ? 17 : 22,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(BuildContext context, {required bool compact}) {
    final theme = FlutterFlowTheme.of(context);
    final padding = compact ? 24.0 : 40.0;
    return Container(
      key: const ValueKey('login-form-card'),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 20 : 24),
        border: Border.all(color: const Color(0xFFE7E3DC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Inicia sesión',
            key: const ValueKey('login-title'),
            style: theme.headlineMedium.copyWith(
              color: _verdeOscuro,
              fontSize: compact ? 30 : 38,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bienvenido de nuevo',
            key: const ValueKey('login-subtitle'),
            style: theme.bodyLarge.copyWith(
              color: theme.secondaryText,
              fontSize: compact ? 16 : 18,
            ),
          ),
          SizedBox(height: compact ? 24 : 30),
          _buildEmailField(context),
          const SizedBox(height: 20),
          _buildPasswordField(context),
          SizedBox(height: compact ? 24 : 28),
          SizedBox(
            width: double.infinity,
            child: FFButtonWidget(
              onPressed: _iniciarSesion,
              text: 'Iniciar sesión',
              options: FFButtonOptions(
                width: double.infinity,
                height: 56,
                padding: EdgeInsets.zero,
                iconPadding: EdgeInsets.zero,
                color: _verdeMarca,
                textStyle: GoogleFonts.interTight(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                elevation: 0,
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Correo',
          style: theme.bodyMedium.copyWith(
            color: theme.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 9),
        TextFormField(
          key: const ValueKey('login-email'),
          controller: _model.emailTextController,
          focusNode: _model.textFieldFocusNode1,
          autofocus: false,
          obscureText: false,
          decoration: _inputDecoration(
            context,
            hint: 'Digite el correo',
            icon: Icons.email_outlined,
          ),
          style: theme.bodyMedium,
          cursorColor: theme.primary,
          validator: _model.emailTextControllerValidator.asValidator(context),
        ),
      ],
    );
  }

  Widget _buildPasswordField(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contraseña',
          style: theme.bodyMedium.copyWith(
            color: theme.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 9),
        TextFormField(
          key: const ValueKey('login-password'),
          controller: _model.passwordTextController,
          focusNode: _model.textFieldFocusNode2,
          autofocus: false,
          obscureText: !_model.passwordVisibility,
          decoration: _inputDecoration(
            context,
            hint: 'Digite la contraseña',
            icon: Icons.key_outlined,
            suffixIcon: IconButton(
              tooltip: _model.passwordVisibility
                  ? 'Ocultar contraseña'
                  : 'Mostrar contraseña',
              onPressed: () => safeSetState(
                () => _model.passwordVisibility = !_model.passwordVisibility,
              ),
              icon: Icon(
                _model.passwordVisibility
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: _verdeMarca,
              ),
            ),
          ),
          style: theme.bodyMedium,
          cursorColor: theme.primary,
          validator:
              _model.passwordTextControllerValidator.asValidator(context),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final theme = FlutterFlowTheme.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFD8D4CC), width: 1),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: theme.bodyMedium.copyWith(color: theme.tertiary),
      prefixIcon: Icon(icon, size: 21),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFFFFEFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: border,
      border: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: theme.primary, width: 1.5),
      ),
      errorBorder: border.copyWith(
        borderSide: BorderSide(color: theme.error, width: 1),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: BorderSide(color: theme.error, width: 1.5),
      ),
    );
  }

  Future<void> _iniciarSesion() async {
    GoRouter.of(context).prepareAuthEvent();

    final user = await authManager.signInWithEmail(
      context,
      _model.emailTextController!.text,
      _model.passwordTextController!.text,
    );
    if (!mounted || user == null) {
      return;
    }

    _model.userquery = await UsuariosTable().queryRows(
      queryFn: (q) => q.eqOrNull(
        'id',
        currentUserUid,
      ),
    );
    if (!mounted) {
      return;
    }
    if (_model.userquery?.firstOrNull?.rol == 'administrador') {
      FFAppState().user = UserStruct(
        nombres: valueOrDefault<String>(
          '${_model.userquery?.firstOrNull?.nombres} ${_model.userquery?.firstOrNull?.apellidos}',
          'Sin nombre',
        ),
        fotoUrl: _model.userquery?.firstOrNull?.fotoPerfilUrl,
      );
      safeSetState(() {});

      context.goNamedAuth(
        DashboardWidget.routeName,
        mounted,
        extra: <String, dynamic>{
          '__transition_info__': const TransitionInfo(
            hasTransition: true,
            transitionType: PageTransitionType.fade,
            duration: Duration.zero,
          ),
        },
      );
    } else {
      GoRouter.of(context).prepareAuthEvent();
      await authManager.signOut();
      if (!mounted) {
        return;
      }
      GoRouter.of(context).clearRedirectLocation();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'El usuario no es administrador',
            style: TextStyle(
                color: FlutterFlowTheme.of(context).primaryBackground),
          ),
          duration: const Duration(milliseconds: 4000),
          backgroundColor: FlutterFlowTheme.of(context).error,
        ),
      );
    }

    safeSetState(() {});
  }
}

class _LoginHeroBackground extends StatelessWidget {
  const _LoginHeroBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF063C2C), Color(0xFF0B6244)],
        ),
      ),
    );
  }
}

class _LoginBottomWaves extends StatelessWidget {
  const _LoginBottomWaves({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: CustomPaint(
        painter: _LoginBottomWavesPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _LoginBottomWavesPainter extends CustomPainter {
  const _LoginBottomWavesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final wave = Path()
      ..moveTo(0, size.height * 0.18)
      ..cubicTo(
        size.width * 0.19,
        size.height * 0.38,
        size.width * 0.34,
        size.height * 0.86,
        size.width * 0.58,
        size.height * 0.88,
      )
      ..cubicTo(
        size.width * 0.78,
        size.height * 0.9,
        size.width * 0.89,
        size.height * 0.45,
        size.width,
        size.height * 0.17,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      wave,
      Paint()..color = const Color(0xFFE8F3E0),
    );

    final accent = Path()
      ..moveTo(0, size.height * 0.04)
      ..cubicTo(
        size.width * 0.21,
        size.height * 0.24,
        size.width * 0.37,
        size.height * 0.69,
        size.width * 0.6,
        size.height * 0.74,
      )
      ..cubicTo(
        size.width * 0.8,
        size.height * 0.78,
        size.width * 0.91,
        size.height * 0.3,
        size.width,
        size.height * 0.04,
      );

    canvas.drawPath(
      accent,
      Paint()
        ..color = const Color(0xFFDCEFD2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..strokeCap = StrokeCap.round,
    );

    final lowerBand = Path()
      ..moveTo(0, size.height * 0.3)
      ..cubicTo(
        size.width * 0.2,
        size.height * 0.46,
        size.width * 0.38,
        size.height * 0.94,
        size.width * 0.62,
        size.height * 0.96,
      )
      ..cubicTo(
        size.width * 0.8,
        size.height * 0.98,
        size.width * 0.92,
        size.height * 0.56,
        size.width,
        size.height * 0.3,
      );

    canvas.drawPath(
      lowerBand,
      Paint()
        ..color = const Color(0xFFF3F8EF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _LoginBottomWavesPainter oldDelegate) => false;
}
