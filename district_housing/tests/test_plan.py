import json
import sys
import unittest
from unittest.mock import patch
from shapely.geometry import box
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]/'tools'))
from plan import plan, sources, Polygon, unary_union

class PlannerTests(unittest.TestCase):
    def test_source_coordinates(self):
        data, layers = sources()
        self.assertEqual(len(data['lots']),19)
        self.assertEqual(len(layers['Parking']),1)

    def test_reproducible(self):
        profile=json.loads((Path(__file__).parent/'synthetic_profile.json').read_text())
        self.assertEqual(plan(profile),plan(profile))

    def test_missing_measurements_fail_closed(self):
        result=plan()
        self.assertEqual(result['buildings'],[])
        self.assertTrue(any('measurements absent' in x for x in result['blockers']))

    def test_positive_synthetic_layout(self):
        profile=json.loads((Path(__file__).parent/'synthetic_profile.json').read_text())
        data,_=sources()
        data['lots']=[dict(data['lots'][4],polygon_xz_m=[[0,0],[60,0],[60,60],[0,60]])]
        layers={'Lots':[box(0,0,60,60)],'Sidewalks':[box(60,0,64,60)],'Roads':[],'Parking':[]}
        with patch('plan.sources',return_value=(data,layers)):
            first=plan(profile)
            self.assertEqual(first,plan(profile))
        self.assertEqual(len(first['buildings']),1)
        self.assertEqual(first['blockers'],[])
        b=first['buildings'][0]
        self.assertGreater(b['door_height'],profile['crouched_height'])
        self.assertLess(b['height'],profile['standing_height'])
        self.assertTrue(box(2.5,2.5,57.5,57.5).covers(Polygon(b['footprint'])))

    def test_bad_profile(self):
        with self.assertRaises(ValueError): plan({'standing_height':4})

    def test_all_accepted_footprints_and_routes(self):
        profile=json.loads((Path(__file__).parent/'synthetic_profile.json').read_text())
        result=plan(profile,'district')
        data,layers=sources()
        lots={l['id']:Polygon(l['polygon_xz_m']) for l in data['lots']}
        forbidden=unary_union([p for layer,ps in layers.items() if layer!='Lots' for p in ps])
        for b in result['buildings']:
            footprint=Polygon(b['support_footprint'])
            self.assertTrue(lots[b['lot']].buffer(-2.5).covers(footprint))
            self.assertFalse(footprint.intersects(forbidden))
        # A zero-placement run is a blocked plan, never a successful district test.
        self.assertTrue(result['buildings'] or result['blockers'])
        for i,a in enumerate(result['buildings']):
            for b in result['buildings'][i+1:]:
                self.assertGreaterEqual(Polygon(a['support_footprint']).distance(Polygon(b['support_footprint'])),3-1e-6)
        self.assertTrue(any('explicit required mecha access' in x for x in result['zoning_overrides']))
        self.assertGreater(len(result['buildings']),0)

if __name__=='__main__': unittest.main()
