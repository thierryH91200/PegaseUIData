

//[PegaseUIData] Notification permission granted: true
//It's not legal to call -layoutSubtreeIfNeeded on a view which is already being laid out.  If you are implementing the view's -layout method, you can call -[super layout] instead.  Break on void _NSDetectedLayoutRecursion(void) to debug.  This will be logged only once.  This may break in the future.
//SwiftData/BackingData.swift:831: Fatal error: This model instance was destroyed by calling ModelContext.reset and is no longer usable. PersistentIdentifier(id: SwiftData.PersistentIdentifier.ID(backing: SwiftData.PersistentIdentifier.PersistentIdentifierBacking.managedObjectID(0x8a5557911f380dc6 <x-coredata://F7A83395-4FC6-4227-889B-0CE524CCB399/EntityRubric/p10>)))
//Message from debugger: killed



//applique ces modifications dans:
// RubricManager (EntityRubric.swift)


//SwiftData/BackingData.swift:831: Fatal error: This model instance was destroyed by calling ModelContext.reset and is no longer usable. PersistentIdentifier(id: SwiftData.PersistentIdentifier.ID(backing: SwiftData.PersistentIdentifier.PersistentIdentifierBacking.managedObjectID(0x92dcb2d908d6f6c2 <x-coredata://A30C69D8-B2E9-4A71-96BA-35A0D4B6C6AE/EntityRubric/p118>)))
