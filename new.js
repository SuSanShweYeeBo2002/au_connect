    // Example Express route
    router.get('/list', authMiddleware, friendController.getFriendsList);
    