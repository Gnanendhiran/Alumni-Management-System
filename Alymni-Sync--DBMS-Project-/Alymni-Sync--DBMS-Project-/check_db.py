from db_connect import execute_query

print("=== Checking Database ===")
degrees = execute_query("SELECT * FROM degrees")
campuses = execute_query("SELECT * FROM campuses")

print(f"Degrees (no filter): {len(degrees) if degrees else 0}")
if degrees:
    for d in degrees:
        print(f"  - {d['name']} (is_active: {d.get('is_active', 'N/A')})")

print(f"\nCampuses (no filter): {len(campuses) if campuses else 0}")
if campuses:
    for c in campuses:
        print(f"  - {c['name']} (is_active: {c.get('is_active', 'N/A')})")

print("\n=== Testing Registration Query ===")
degrees_filtered = execute_query("SELECT * FROM degrees WHERE is_active = 1 ORDER BY name")
campuses_filtered = execute_query("SELECT * FROM campuses WHERE is_active = 1 ORDER BY name")

print(f"Degrees (is_active=1): {len(degrees_filtered) if degrees_filtered else 0}")
print(f"Campuses (is_active=1): {len(campuses_filtered) if campuses_filtered else 0}")
