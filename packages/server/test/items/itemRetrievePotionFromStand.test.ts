import { commonSetup, world, itemGenerator } from '../testSetup';
import { DB } from '../../src/services/database';
import { mobFactory } from '../../src/mobs/mobFactory';
import { Community } from '../../src/community/community';
import { Item } from '../../src/items/item';
import { AddItem } from '../../src/items/uses/container/addItem';
import { GetItem } from '../../src/items/uses/container/getItem';
import { Mob } from '../../src/mobs/mob';
import { Coord } from '@rt-potion/common';

beforeEach(() => {
  commonSetup();
  Community.makeVillage('alchemists', 'Alchemists guild');
  Community.makeVillage('blacksmiths', 'Blacksmith Guild');
  mobFactory.loadTemplates(world.mobTypes);
});

describe('Potion Stand Ownership Tests', () => {
  describe('Potion Stand Ownership and Community ID Tests', () => {
  test('Blacksmith can place potion, retrieve it, but Alchemist can not since wrong community', () => {

      const standPosition: Coord = { x: 0, y: 1 };
      const playerPosition: Coord = { x: 0, y: 0 };
      const potionLocation: Coord = { x: 1, y: 0 };

      // Create a potion stand (owned by Blacksmith community)
      itemGenerator.createItem({
        type: 'potion-stand',
        subtype: '255',
        position: standPosition,
        attributes: {
          templateType: 'potion',
          ownedBy: 'blacksmiths'
        },
      });
      const standID = Item.getItemIDAt(standPosition);
      expect(standID).not.toBeNull();

      const potionStand = Item.getItem(standID!);
      expect(potionStand).toBeDefined();

      // Create a Blacksmith community player
      mobFactory.makeMob('player', playerPosition, 'BlacksmithID', 'BlacksmithPlayer', 'blacksmiths');
      const blacksmithPlayer = Mob.getMob('BlacksmithID');
      expect(blacksmithPlayer).toBeDefined();
      expect(blacksmithPlayer!.carrying).toBeUndefined();          
      expect(blacksmithPlayer!.community_id).toBe('blacksmiths');

       // Create an Alchemist community player
       mobFactory.makeMob('player', playerPosition, 'AlchemistID', 'AlchemistPlayer', 'alchemists');
      const alchemistPlayer = Mob.getMob('AlchemistID');
      expect(alchemistPlayer).toBeDefined();
      expect(alchemistPlayer!.carrying).toBeUndefined(); 
      expect(alchemistPlayer!.community_id).toBe('alchemists');

      // Create a potion owned by blacksmiths and give it to the blacksmith player
      itemGenerator.createItem({
        type: 'potion',
        subtype: '255',
        position: potionLocation,
        carriedBy: blacksmithPlayer
      });

      // Blacksmith place potion on the stand
      const addPotion = new AddItem();
      addPotion.interact(blacksmithPlayer!, potionStand!);

      // Verify the potion is now on the stand
      expect(potionStand!.getAttribute('items')).toBe(1);

      // Verify Blacksmith is not carrying anything
      expect(blacksmithPlayer!.carrying).toBeUndefined();

      // Blacksmith retrieves the potion from the stand
      const retrievePotion = new GetItem();
      const resultBlacksmith = retrievePotion.interact(blacksmithPlayer!, potionStand!);
      expect(resultBlacksmith).toBe(true); // success since blacksmith owns stand

      // Verify the stand is empty
      expect(potionStand!.getAttribute('items')).toBe(0);

      // Verify Blacksmith now has the potion
      expect(blacksmithPlayer!.carrying).not.toBeNull();
      expect(blacksmithPlayer!.carrying!.type).toBe('potion');   

      // Blacksmith replaces potion on the stand
      const replacePotion = new AddItem();
      replacePotion.interact(blacksmithPlayer!, potionStand!);

      // Verify the potion is now on the stand
      expect(potionStand!.getAttribute('items')).toBe(1);

      // Verify Blacksmith is not carrying anything
      expect(blacksmithPlayer!.carrying).toBeUndefined();

      // Alchemist tries to retrieve potion (fail)
      const retrievePotionAlchemist = new GetItem();
      const resultAlchemist = retrievePotionAlchemist.interact(alchemistPlayer!, potionStand!);
      expect(resultAlchemist).toBe(false); // fail since blacksmith owns stand
    });
  });
});

afterEach(() => {
  DB.close();
});
