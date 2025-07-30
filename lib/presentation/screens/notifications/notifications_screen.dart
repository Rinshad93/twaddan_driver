import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/utils/bloc_extensions.dart';
import '../../../data/models/notification_model.dart';
import '../../bloc/notification/notification_bloc.dart';
import '../../bloc/notification/notification_event.dart';
import '../../bloc/notification/notification_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Initialize notifications if not already done
    context.read<NotificationBloc>().add(const NotificationInitialize());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Orders'),
            Tab(text: 'Earnings'),
            Tab(text: 'Alerts'),
          ],
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
        ),
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              if (state is NotificationLoaded && state.unreadCount > 0) {
                return PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'mark_all_read':
                        context.read<NotificationBloc>().add(
                          const NotificationMarkAllAsRead(),
                        );
                        break;
                      case 'clear_all':
                        _showClearAllDialog();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'mark_all_read',
                      child: Text('Mark all as read'),
                    ),
                    const PopupMenuItem(
                      value: 'clear_all',
                      child: Text('Clear all'),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<NotificationBloc, NotificationState>(
        listener: (context, state) {
          if (state is NotificationError) {
            context.showErrorSnackBar(state.message);
          } else if (state is NotificationActionTriggered) {
            _handleNotificationAction(state.notification, state.action);
          } else if (state is NotificationPermissionDenied) {
            _showPermissionDialog();
          }
        },
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is NotificationLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationsList(state.notifications, 'all'),
                _buildNotificationsList(
                  state.notifications.where((n) =>
                  n.type == NotificationType.newOrder ||
                      n.type == NotificationType.orderUpdate
                  ).toList(),
                  'orders',
                ),
                _buildNotificationsList(
                  state.notifications.where((n) =>
                  n.type == NotificationType.earnings
                  ).toList(),
                  'earnings',
                ),
                _buildNotificationsList(
                  state.notifications.where((n) =>
                  n.type == NotificationType.emergency ||
                      n.type == NotificationType.general
                  ).toList(),
                  'alerts',
                ),
              ],
            );
          } else if (state is NotificationPermissionDenied) {
            return _buildPermissionDeniedView();
          } else {
            return _buildEmptyState();
          }
        },
      ),
    );
  }

  Widget _buildNotificationsList(List<NotificationModel> notifications, String filter) {
    if (notifications.isEmpty) {
      return _buildEmptyState(filter: filter);
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<NotificationBloc>().add(const NotificationInitialize());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppDimensions.spaceM),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: notification.isRead
              ? Colors.transparent
              : AppColors.primary.withOpacity(0.3),
          width: notification.isRead ? 0 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textHint.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.read<NotificationBloc>().add(
              NotificationTapped(notification),
            );
          },
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.spaceS),
                      decoration: BoxDecoration(
                        color: _getNotificationColor(notification.type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                      ),
                      child: Icon(
                        _getNotificationIcon(notification.type),
                        color: _getNotificationColor(notification.type),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notification.title,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: notification.isRead
                                        ? FontWeight.normal
                                        : FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (!notification.isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.spaceXS),
                          Text(
                            notification.displayTime,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleNotificationMenu(notification, value),
                      itemBuilder: (context) => [
                        if (!notification.isRead)
                          const PopupMenuItem(
                            value: 'mark_read',
                            child: Text('Mark as read'),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                      child: const Icon(
                        Icons.more_vert,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceM),
                Text(
                  notification.body,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (notification.hasActions) ...[
                  const SizedBox(height: AppDimensions.spaceM),
                  _buildNotificationActions(notification),
                ],
                if (notification.imageUrl != null) ...[
                  const SizedBox(height: AppDimensions.spaceM),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    child: Image.network(
                      notification.imageUrl!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 120,
                        color: AppColors.surfaceVariant,
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationActions(NotificationModel notification) {
    if (notification.type == NotificationType.newOrder) {
      return Row(
        children: [
          Expanded(
            child: CustomButton(
              text: 'Accept Order',
              onPressed: () => _handleOrderAction(notification, 'accept'),
              variant: ButtonVariant.primary,
              size: ButtonSize.small,
            ),
          ),
          const SizedBox(width: AppDimensions.spaceS),
          Expanded(
            child: CustomButton(
              text: 'Decline',
              onPressed: () => _handleOrderAction(notification, 'decline'),
              variant: ButtonVariant.outline,
              size: ButtonSize.small,
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildEmptyState({String? filter}) {
    String title;
    String message;
    IconData icon;

    switch (filter) {
      case 'orders':
        title = 'No Order Notifications';
        message = 'Order updates will appear here';
        icon = Icons.local_shipping;
        break;
      case 'earnings':
        title = 'No Earnings Notifications';
        message = 'Earnings summaries will appear here';
        icon = Icons.account_balance_wallet;
        break;
      case 'alerts':
        title = 'No Alert Notifications';
        message = 'Important alerts will appear here';
        icon = Icons.notification_important;
        break;
      default:
        title = 'No Notifications';
        message = 'You\'re all caught up!';
        icon = Icons.notifications_none;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spaceXL),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceL),
            Text(
              title,
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceS),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spaceXL),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_off,
                size: 64,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceL),
            Text(
              'Notifications Disabled',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceS),
            Text(
              'Enable notifications to receive order updates and important alerts.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spaceL),
            CustomButton(
              text: 'Enable Notifications',
              onPressed: () {
                context.read<NotificationBloc>().add(
                  const NotificationPermissionRequested(),
                );
              },
              variant: ButtonVariant.primary,
              prefixIcon: const Icon(
                Icons.notifications,
                color: AppColors.surface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.newOrder:
        return AppColors.success;
      case NotificationType.orderUpdate:
        return AppColors.info;
      case NotificationType.earnings:
        return AppColors.warning;
      case NotificationType.emergency:
        return AppColors.error;
      case NotificationType.promotional:
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.newOrder:
        return Icons.local_shipping;
      case NotificationType.orderUpdate:
        return Icons.update;
      case NotificationType.earnings:
        return Icons.account_balance_wallet;
      case NotificationType.emergency:
        return Icons.emergency;
      case NotificationType.promotional:
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }

  void _handleNotificationAction(NotificationModel notification, String action) {
    switch (action) {
      case 'tap':
        _navigateBasedOnNotification(notification);
        break;
      default:
        break;
    }
  }

  void _navigateBasedOnNotification(NotificationModel notification) {
    switch (notification.type) {
      case NotificationType.newOrder:
      case NotificationType.orderUpdate:
        if (notification.orderId != null) {
          // Navigate to order details
          context.showInfoSnackBar('Opening order ${notification.orderId}');
        }
        break;
      case NotificationType.earnings:
      // Navigate to earnings screen
        context.showInfoSnackBar('Opening earnings summary');
        break;
      case NotificationType.emergency:
      // Handle emergency notification
        context.showErrorSnackBar('Emergency: ${notification.body}');
        break;
      default:
        break;
    }
  }

  void _handleNotificationMenu(NotificationModel notification, String action) {
    switch (action) {
      case 'mark_read':
        context.read<NotificationBloc>().add(
          NotificationMarkAsRead(notification.id),
        );
        break;
      case 'delete':
        context.read<NotificationBloc>().add(
          NotificationDelete(notification.id),
        );
        break;
    }
  }

  void _handleOrderAction(NotificationModel notification, String action) {
    switch (action) {
      case 'accept':
        if (notification.orderId != null) {
          context.showSuccessSnackBar('Order ${notification.orderId} accepted!');
          // Mark notification as read
          context.read<NotificationBloc>().add(
            NotificationMarkAsRead(notification.id),
          );
        }
        break;
      case 'decline':
        if (notification.orderId != null) {
          context.showInfoSnackBar('Order ${notification.orderId} declined');
          // Mark notification as read
          context.read<NotificationBloc>().add(
            NotificationMarkAsRead(notification.id),
          );
        }
        break;
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to clear all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<NotificationBloc>().add(
                const NotificationClearAll(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.surface,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Notifications'),
        content: const Text(
          'Notifications are disabled. Would you like to enable them to receive important updates about orders and earnings?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<NotificationBloc>().add(
                const NotificationPermissionRequested(),
              );
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }
}